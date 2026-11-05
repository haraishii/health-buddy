package api

import (
	"context"
	"fmt"
	"log"
	"regexp"
	"strings"
	"time"

	"github.com/iwinardhyas/health-buddy/backend/internal/ollama"
)

// aiReply answers a free question with the AI model, grounded in the user's data. It returns a nil reply
// (and no error) when the model fails or is too slow, so the caller falls back to the rule-based answer.
// Restricted topics never reach this: askCoach answers them with the reviewed safe answer first.
func (s *Server) aiReply(ctx context.Context, userID int64, p *period, topic, question string) (*coachReply, error) {
	// The rule-based answer gives the model checked facts and reviewed tips to build on.
	factTopic := topic
	if factTopic == "" {
		factTopic = "general"
	}
	facts, err := s.composeReply(ctx, p, factTopic)
	if err != nil {
		return nil, err
	}
	history, err := s.recentChat(ctx, userID, 6)
	if err != nil {
		return nil, err
	}

	messages := append([]ollama.Message{{Role: "system", Content: aiSystemPrompt(p, facts)}}, history...)
	messages = append(messages, ollama.Message{Role: "user", Content: question})

	aiCtx, cancel := context.WithTimeout(ctx, s.cfg.OllamaTimeout)
	defer cancel()
	start := time.Now()
	answer, err := s.ai.Chat(aiCtx, messages)
	if err != nil {
		log.Printf("ai coach: %v (after %s); using the rule-based answer", err, time.Since(start).Round(time.Millisecond))
		return nil, nil
	}
	return &coachReply{Kind: "answer", Text: cleanModelText(answer), Points: []coachPoint{},
		Recommendations: []string{}, Model: s.ai.Model}, nil
}

// recentChat returns up to n messages from the last day, oldest first, so follow-up questions have context.
func (s *Server) recentChat(ctx context.Context, userID int64, n int) ([]ollama.Message, error) {
	rows, err := s.db.Query(ctx, `
		SELECT role, text FROM (
			SELECT role, text, created_at, id FROM coach_chat_messages
			WHERE user_id = $1 AND created_at > now() - interval '1 day'
			ORDER BY created_at DESC, id DESC LIMIT $2
		) AS latest ORDER BY created_at, id`, userID, n)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	var out []ollama.Message
	for rows.Next() {
		var role, text string
		if err := rows.Scan(&role, &text); err != nil {
			return nil, err
		}
		if role == "coach" {
			role = "assistant"
		}
		out = append(out, ollama.Message{Role: role, Content: text})
	}
	return out, rows.Err()
}

// aiSystemPrompt holds the coach's rules and the user's data. It leaves out name and email on purpose.
func aiSystemPrompt(p *period, facts *coachReply) string {
	language := `Bahasa Indonesia (casual and friendly, call the user "kamu")`
	if p.user.Language == "en" {
		language = `English (casual and friendly, call the user "you")`
	}
	var b strings.Builder
	fmt.Fprintf(&b, `You are Health Buddy, the AI wellness coach inside a healthy-lifestyle app.
Always answer in %s, warm and encouraging.

Rules:
- Give lifestyle tips only: food and nutrition, drinking water, sleep, physical activity and stress. You are not a doctor.
- Never diagnose, never name or dose medicines or supplements, never interpret symptoms or lab results.
  For symptoms, illness, medicines, pregnancy or anything serious, say kindly that a doctor or other health professional should check it.
- Personal statements must come from the user data below. Never invent numbers. If data is missing, say what to log in the app.
- If the question is not about health or using the app, answer in one sentence that you can only help with healthy habits.
- Keep it short: at most 120 words and at most 3 concrete tips.
- Plain text only: no markdown, no headings, no bold, no tables. For a list, start each line with "• ".

User data from the app:
`, language)
	b.WriteString(aiUserData(p))

	if len(facts.Points) > 0 {
		b.WriteString("\nFacts the app worked out for this question:\n")
		for _, pt := range facts.Points {
			b.WriteString("• " + pt.Text + "\n")
		}
	}
	if len(facts.Recommendations) > 0 {
		b.WriteString("\nReviewed tips that fit this user (prefer these):\n")
		for _, r := range facts.Recommendations {
			b.WriteString("• " + r + "\n")
		}
	}
	return b.String()
}

func aiUserData(p *period) string {
	var b strings.Builder
	line := func(label string, parts []string) {
		if len(parts) > 0 {
			fmt.Fprintf(&b, "%s: %s\n", label, strings.Join(parts, ", "))
		}
	}

	u := p.user
	var profile []string
	if u.Age != nil {
		profile = append(profile, fmt.Sprintf("age %d", *u.Age))
	}
	if u.Sex != nil {
		profile = append(profile, "sex "+*u.Sex)
	}
	if u.HeightCm != nil {
		profile = append(profile, fmt.Sprintf("height %g cm", *u.HeightCm))
	}
	if u.WeightKg != nil {
		profile = append(profile, fmt.Sprintf("weight %g kg", *u.WeightKg))
	}
	if u.LifeStage != "" && u.LifeStage != "general" {
		profile = append(profile, "life stage "+u.LifeStage)
	}
	line("Profile", profile)

	if t := p.targets; t != nil {
		targets := []string{fmt.Sprintf("%.0f kcal", t.EnergyKcal), fmt.Sprintf("protein %.0f g", t.ProteinG),
			fmt.Sprintf("fiber %.0f g", t.FiberG), fmt.Sprintf("water %.0f ml", t.WaterMl), fmt.Sprintf("%d steps", t.StepsTarget)}
		if t.SleepHoursMin != nil && t.SleepHoursMax != nil {
			targets = append(targets, fmt.Sprintf("sleep %g-%g h", *t.SleepHoursMin, *t.SleepHoursMax))
		}
		line("Daily targets", targets)
	} else {
		b.WriteString("Daily targets: unknown, the profile is missing birth date or sex\n")
	}

	if len(p.days) > 0 {
		d := p.last()
		today := []string{fmt.Sprintf("%.0f kcal eaten", d.CaloriesIn), fmt.Sprintf("protein %.0f g", d.ProteinG),
			fmt.Sprintf("fiber %.0f g", d.FiberG), fmt.Sprintf("water %.0f ml", d.WaterMl),
			fmt.Sprintf("exercise %d min", d.ExerciseMinutes)}
		if d.Steps != nil {
			today = append(today, fmt.Sprintf("%d steps", *d.Steps))
		}
		if d.SleepHours != nil {
			today = append(today, fmt.Sprintf("slept %.1f h", *d.SleepHours))
		}
		if d.StressAvg != nil {
			today = append(today, fmt.Sprintf("stress %.1f/10", *d.StressAvg))
		}
		line("Today so far ("+d.Date+")", today)
	}

	a := p.now
	week := []string{fmt.Sprintf("food logged on %d days", a.LoggedFoodDays), fmt.Sprintf("exercised on %d days", a.ExerciseDays)}
	if a.LoggedFoodDays > 0 {
		week = append(week, fmt.Sprintf("%.0f kcal and protein %.0f g per logged day", a.CaloriesIn, a.ProteinG))
	}
	if a.SleepHours != nil {
		week = append(week, fmt.Sprintf("sleep %.1f h", *a.SleepHours))
	}
	if a.Steps != nil {
		week = append(week, fmt.Sprintf("%.0f steps", *a.Steps))
	}
	if a.Stress != nil {
		week = append(week, fmt.Sprintf("stress %.1f/10 (10 = very stressed), %d high-stress days", *a.Stress, a.HighStressDays))
	}
	line("Last 7 days (averages)", week)
	return b.String()
}

var (
	mdHeading = regexp.MustCompile(`(?m)^[ \t]*#{1,6}[ \t]+`)
	mdBullet  = regexp.MustCompile(`(?m)^[ \t]*[-*+][ \t]+`)
	manyLines = regexp.MustCompile(`\n{3,}`)
)

// cleanModelText turns stray markdown into the plain text the app's chat bubble shows.
func cleanModelText(s string) string {
	s = strings.ReplaceAll(s, "\r\n", "\n")
	s = strings.NewReplacer("**", "", "__", "", "`", "").Replace(s)
	s = mdHeading.ReplaceAllString(s, "")
	s = mdBullet.ReplaceAllString(s, "• ")
	s = manyLines.ReplaceAllString(s, "\n\n")
	return truncateRunes(strings.TrimSpace(s), 1500)
}
