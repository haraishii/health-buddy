package api

import (
	"context"
	"encoding/json"
	"math"
	"net/http"
	"strconv"
	"strings"
	"time"
)

// Rule-based AI Coach: answers are built from the user's last 7 days, the tips (7A), the sentence templates
// and the restricted topics (7C). No free-form AI model yet, so it never gives medical advice.

type coachPoint struct {
	Topic string `json:"topic"` // sleep, protein, stress, ... (the app picks an icon)
	Text  string `json:"text"`
}

type coachReply struct {
	Kind                 string       `json:"kind"` // answer, restricted or fallback
	Text                 string       `json:"text"`
	Points               []coachPoint `json:"points"`
	RecommendationsTitle string       `json:"recommendations_title,omitempty"`
	Recommendations      []string     `json:"recommendations"`
	Referral             string       `json:"referral,omitempty"`
}

type ChatMessage struct {
	ID        int64       `json:"id"`
	Role      string      `json:"role"`
	Text      string      `json:"text"`
	Reply     *coachReply `json:"reply,omitempty"` // coach messages only
	CreatedAt time.Time   `json:"created_at"`
}

// topicKeywords recognise the subject of a typed question (English and Indonesian).
var topicKeywords = []struct {
	topic string
	words []string
}{
	{"sleep", []string{"sleep", "tired", "tidur", "capek", "lelah", "ngantuk", "insomnia"}},
	{"stress", []string{"stress", "stres", "anxious", "cemas", "worried", "khawatir", "relax"}},
	{"drinking water", []string{"water", "drink", "minum", "air putih", "hydrat"}},
	{"activity", []string{"exercise", "olahraga", "steps", "langkah", "walk", "jalan", "run", "lari", "sport", "gym"}},
	{"food and nutrition", []string{"eat", "food", "makan", "protein", "meal", "snack", "gizi", "nutrition", "diet"}},
	{"general", []string{"progress", "week", "minggu", "score", "skor", "analy", "summary", "ringkas"}},
}

// askCoach: POST /api/v1/me/coach/ask {"question_id": "QQ01"} or {"text": "..."}. Saves both messages.
func (s *Server) askCoach(w http.ResponseWriter, r *http.Request, userID int64) {
	var in struct {
		QuestionID string `json:"question_id"`
		Text       string `json:"text"`
	}
	if !decode(w, r, &in) {
		return
	}
	ctx := r.Context()
	in.Text = strings.TrimSpace(in.Text)

	day, err := parseDate(r.URL.Query().Get("date"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "date must be YYYY-MM-DD")
		return
	}
	p, err := s.loadPeriod(ctx, userID, day.AddDate(0, 0, -6), day)
	if err != nil {
		serverError(w, err)
		return
	}
	lang := p.user.Language

	topic := ""
	if in.QuestionID != "" {
		err := s.db.QueryRow(ctx, `
			SELECT topic, CASE WHEN $2 = 'en' THEN COALESCE(question_text_en, question_text) ELSE question_text END
			FROM coach_quick_questions WHERE id = $1`, in.QuestionID, lang).Scan(&topic, &in.Text)
		if isNoRows(err) {
			writeError(w, http.StatusNotFound, "quick question not found")
			return
		}
		if err != nil {
			serverError(w, err)
			return
		}
	}
	if in.Text == "" || len(in.Text) > 500 {
		writeError(w, http.StatusBadRequest, "text must be 1 to 500 characters")
		return
	}

	reply, err := s.restrictedReply(ctx, in.Text, lang)
	if err != nil {
		serverError(w, err)
		return
	}
	if reply == nil {
		if topic == "" {
			topic = detectTopic(in.Text)
		}
		if reply, err = s.composeReply(ctx, p, topic); err != nil {
			serverError(w, err)
			return
		}
	}

	payload, _ := json.Marshal(reply)
	var userMsg, coachMsg ChatMessage
	err = s.db.QueryRow(ctx, `
		WITH u AS (INSERT INTO coach_chat_messages (user_id, role, text) VALUES ($1, 'user', $2) RETURNING id, created_at),
		     c AS (INSERT INTO coach_chat_messages (user_id, role, text, payload) VALUES ($1, 'coach', $3, $4)
		           RETURNING id, created_at)
		SELECT u.id, u.created_at, c.id, c.created_at FROM u, c`,
		userID, in.Text, reply.plainText(), payload).Scan(&userMsg.ID, &userMsg.CreatedAt, &coachMsg.ID, &coachMsg.CreatedAt)
	if err != nil {
		serverError(w, err)
		return
	}
	userMsg.Role, userMsg.Text = "user", in.Text
	coachMsg.Role, coachMsg.Text, coachMsg.Reply = "coach", reply.plainText(), reply
	writeJSON(w, http.StatusCreated, map[string]any{"question": userMsg, "answer": coachMsg})
}

func detectTopic(text string) string {
	lower := strings.ToLower(text)
	for _, t := range topicKeywords {
		for _, w := range t.words {
			if strings.Contains(lower, w) {
				return t.topic
			}
		}
	}
	return ""
}

// restrictedReply answers Package 7C topics with the reviewed safe answer instead of advice.
func (s *Server) restrictedReply(ctx context.Context, text, lang string) (*coachReply, error) {
	rows, err := s.db.Query(ctx, `
		SELECT keywords, CASE WHEN $1 = 'en' THEN COALESCE(safe_answer_en, safe_answer) ELSE safe_answer END,
		       support_referral
		FROM coach_restricted_topics ORDER BY id DESC`, lang) // RT06 (self-harm) is checked before milder topics
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	lower := strings.ToLower(text)
	for rows.Next() {
		var keywords []string
		var answer, referral string
		if err := rows.Scan(&keywords, &answer, &referral); err != nil {
			return nil, err
		}
		for _, k := range keywords {
			if strings.Contains(lower, strings.ToLower(k)) {
				return &coachReply{Kind: "restricted", Text: answer, Points: []coachPoint{}, Recommendations: []string{},
					Referral: referral}, nil
			}
		}
	}
	return nil, rows.Err()
}

func (s *Server) composeReply(ctx context.Context, p *period, topic string) (*coachReply, error) {
	t, err := s.loadTemplates(ctx, p.user.Language)
	if err != nil {
		return nil, err
	}
	if topic == "" {
		return &coachReply{Kind: "fallback", Text: t.fill("coach_fallback", nil), Points: []coachPoint{},
			Recommendations: []string{}}, nil
	}
	tips, err := s.matchingTips(ctx, p)
	if err != nil {
		return nil, err
	}

	reply := &coachReply{Kind: "answer", Text: t.fill("coach_intro_generic", nil), Points: []coachPoint{},
		RecommendationsTitle: t.fill("coach_recommendations", nil), Recommendations: []string{}}
	add := func(topic, text string) {
		if text != "" {
			reply.Points = append(reply.Points, coachPoint{Topic: topic, Text: text})
		}
	}
	today, lang := p.last(), p.user.Language
	wantTips := map[string]bool{}

	switch topic {
	case "sleep":
		reply.Text = t.fill("coach_intro_tired", nil)
		if p.now.SleepHours != nil && p.prev.SleepHours != nil && *p.prev.SleepHours-*p.now.SleepHours >= 0.5 {
			add("sleep", t.fill("sleep_drop_vs_last_week", map[string]any{"hours": round1(*p.prev.SleepHours - *p.now.SleepHours)}))
		} else if p.now.SleepHours != nil {
			add("sleep", t.fill("coach_sleep_avg", map[string]any{"hours": *p.now.SleepHours}))
		}
		if n := p.proteinBelowDays(); n >= 3 {
			add("protein", t.fill("protein_below_target_days", map[string]any{"days": n}))
		}
		if p.now.HighStressDays >= 2 {
			add("stress", t.fill("high_stress_days", map[string]any{"days": p.now.HighStressDays}))
		}
		wantTips = map[string]bool{"sleep": true, "protein": true, "stress": true, "drinking water": true}
	case "food and nutrition", "protein":
		if p.targets != nil {
			if left := p.targets.ProteinG - today.ProteinG; left > 0 {
				add("protein", t.fill("coach_protein_left", map[string]any{"grams": math.Round(left), "target": p.targets.ProteinG}))
			} else {
				add("protein", t.fill("coach_protein_done", map[string]any{"grams": today.ProteinG}))
			}
		}
		add("food and nutrition", p.healthyMealsSentence(t))
		wantTips = map[string]bool{"food and nutrition": true, "protein": true}
	case "stress":
		if p.now.Stress != nil {
			add("stress", t.fill("coach_stress_avg", map[string]any{"level": *p.now.Stress}))
		}
		if pct := percentChange(p.now.StressExerciseDay, p.now.StressRestDay); pct != nil && *pct < 0 {
			add("activity", t.fill("stress_lower_on_exercise_days", map[string]any{"percent": -*pct}))
		}
		if p.now.HighStressDays >= 2 {
			add("stress", t.fill("high_stress_days", map[string]any{"days": p.now.HighStressDays}))
		}
		wantTips = map[string]bool{"stress": true, "activity": true}
	case "drinking water":
		if p.targets != nil {
			add("drinking water", t.fill("coach_water_today", map[string]any{"ml": today.WaterMl, "target": p.targets.WaterMl}))
		}
		wantTips = map[string]bool{"drinking water": true}
	case "activity":
		if p.now.Steps != nil && p.targets != nil {
			add("activity", t.fill("coach_steps_avg", map[string]any{"steps": math.Round(*p.now.Steps), "target": p.targets.StepsTarget}))
		}
		wantTips = map[string]bool{"activity": true}
	default: // general / weekly progress
		now, prev := p.scores(p.days), p.scores(p.prevDays)
		sum := summarizeScores(now, prev)
		if sum.Average != nil {
			change := 0.0
			if sum.ChangePercent != nil {
				change = *sum.ChangePercent
			}
			add("general", t.fill("coach_score", map[string]any{"score": *sum.Average, "change": change}))
		}
		best := -1
		for i, d := range now {
			if d.Score != nil && (best < 0 || *d.Score > *now[best].Score) {
				best = i
			}
		}
		if best >= 0 {
			add("general", t.fill("coach_best_day", map[string]any{"day": weekdayName(now[best].Date, lang), "score": *now[best].Score}))
		}
		if key, v, ok := sum.Balance.weakestPart(); ok {
			add(key, t.fill("coach_weakest", map[string]any{"component": componentName(key, lang), "score": v}))
		}
	}

	for _, tip := range tips {
		if len(reply.Recommendations) == 3 {
			break
		}
		if len(wantTips) == 0 || wantTips[tip.Topic] {
			reply.Recommendations = append(reply.Recommendations, tip.Text)
		}
	}
	if p.targets == nil {
		add("general", t.fill("coach_profile_needed", nil))
	}
	if len(reply.Points) == 0 && len(reply.Recommendations) == 0 {
		reply.Text = t.fill("coach_no_data", nil)
	}
	return reply, nil
}

// plainText is what History shows and what is stored in coach_chat_messages.text.
func (r *coachReply) plainText() string {
	parts := []string{r.Text}
	for _, p := range r.Points {
		parts = append(parts, "• "+p.Text)
	}
	if len(r.Recommendations) > 0 {
		parts = append(parts, r.RecommendationsTitle)
		for _, rec := range r.Recommendations {
			parts = append(parts, "✓ "+rec)
		}
	}
	if r.Referral != "" {
		parts = append(parts, r.Referral)
	}
	text := strings.Join(parts, "\n")
	if len(text) > 2000 {
		text = text[:2000]
	}
	return text
}

// coachHistory: GET /api/v1/me/coach/history?limit=50 returns the latest messages, oldest first.
func (s *Server) coachHistory(w http.ResponseWriter, r *http.Request, userID int64) {
	limit := 50
	if v, err := strconv.Atoi(r.URL.Query().Get("limit")); err == nil && v > 0 && v <= 200 {
		limit = v
	}
	rows, err := s.db.Query(r.Context(), `
		SELECT id, role, text, payload, created_at FROM (
			SELECT * FROM coach_chat_messages WHERE user_id = $1 ORDER BY created_at DESC, id DESC LIMIT $2
		) AS latest ORDER BY created_at, id`, userID, limit)
	if err != nil {
		serverError(w, err)
		return
	}
	defer rows.Close()
	items := []ChatMessage{}
	for rows.Next() {
		var m ChatMessage
		var payload []byte
		if err := rows.Scan(&m.ID, &m.Role, &m.Text, &payload, &m.CreatedAt); err != nil {
			serverError(w, err)
			return
		}
		if len(payload) > 0 {
			m.Reply = &coachReply{}
			if err := json.Unmarshal(payload, m.Reply); err != nil {
				m.Reply = nil
			}
		}
		items = append(items, m)
	}
	if err := rows.Err(); err != nil {
		serverError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"items": items})
}
