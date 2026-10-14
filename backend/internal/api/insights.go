package api

import (
	"context"
	"errors"
	"fmt"
	"math"
	"sort"
	"strings"
	"time"
)

// period is everything the API knows about one user for a date range and the range of the same length
// just before it. Home, Analytics, Food and the AI Coach all read from it, so they always agree.
type period struct {
	user    User
	targets *Targets // nil when the profile is incomplete
	// targetsError says why targets is nil, e.g. no birth date yet.
	targetsError *string
	from, to     time.Time
	days         []DayStats // from..to, including days without data
	prevDays     []DayStats
	now          periodAverages // averages over days up to today only
	prev         periodAverages
	settings     map[string]float64 // app_defaults

	healthyMeals, prevHealthyMeals int
	friedSnackDays                 int  // days in the range with a 'snack and fried food' item
	vegetablesOnLastDay            bool // a 'vegetable' item on the period's "today" (see last)
}

func (s *Server) loadPeriod(ctx context.Context, userID int64, from, to time.Time) (*period, error) {
	p := &period{from: from, to: to}
	var err error
	if p.user, err = scanUser(s.db.QueryRow(ctx, `SELECT `+userColumns+` FROM users WHERE id = $1`, userID)); err != nil {
		return nil, err
	}
	if t, err := s.targetsFor(ctx, p.user); err == nil {
		p.targets = &t
	} else if errors.Is(err, errProfileIncomplete) || errors.Is(err, errNoTargets) {
		msg := err.Error()
		p.targetsError = &msg
	} else {
		return nil, err
	}

	length := int(to.Sub(from).Hours()/24) + 1
	prevFrom := from.AddDate(0, 0, -length)
	if p.days, err = s.dayStats(ctx, userID, from, to); err != nil {
		return nil, err
	}
	if p.prevDays, err = s.dayStats(ctx, userID, prevFrom, from.AddDate(0, 0, -1)); err != nil {
		return nil, err
	}
	p.now, p.prev = averages(untilToday(p.days)), averages(untilToday(p.prevDays))

	rows, err := s.db.Query(ctx, `SELECT key, value::float8 FROM app_defaults`)
	if err != nil {
		return nil, err
	}
	p.settings = map[string]float64{}
	for rows.Next() {
		var k string
		var v float64
		if err := rows.Scan(&k, &v); err != nil {
			return nil, err
		}
		p.settings[k] = v
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	// Healthy meals use the same label rules as the Food page.
	meals, err := queryAll[MealLog](ctx, s.db, `
		WITH m AS (SELECT * FROM meal_logs WHERE user_id = $1 AND logged_on BETWEEN $2 AND $3)`+mealSelect,
		userID, prevFrom, to)
	if err != nil {
		return nil, err
	}
	rules, err := s.labelRules(ctx)
	if err != nil {
		return nil, err
	}
	fromStr, lastStr := from.Format(dateLayout), p.last().Date
	fried := map[string]bool{}
	for i := range meals {
		m := &meals[i]
		healthy := false
		for _, l := range evaluateLabels(rules, m.nutrients()) {
			healthy = healthy || l == "Healthy"
		}
		inRange := m.LoggedOn >= fromStr
		switch {
		case healthy && inRange:
			p.healthyMeals++
		case healthy:
			p.prevHealthyMeals++
		}
		if inRange && m.Category == "snack and fried food" {
			fried[m.LoggedOn] = true
		}
		if m.LoggedOn == lastStr && m.Category == "vegetable" {
			p.vegetablesOnLastDay = true
		}
	}
	p.friedSnackDays = len(fried)
	return p, nil
}

// untilToday drops future days (e.g. the rest of the current week) so they do not pull averages down.
func untilToday(days []DayStats) []DayStats {
	today := time.Now().Format(dateLayout)
	out := days[:0:0]
	for _, d := range days {
		if d.Date <= today {
			out = append(out, d)
		}
	}
	return out
}

// last is the most recent day that is not in the future (the period's "today").
func (p *period) last() DayStats {
	if past := untilToday(p.days); len(past) > 0 {
		return past[len(past)-1]
	}
	return p.days[0]
}

// hasData is false for a period where the user logged nothing at all (e.g. a new account),
// so no tip pretends to know their habits.
func (p *period) hasData() bool {
	for _, d := range untilToday(p.days) {
		if d.CaloriesIn > 0 || d.WaterMl > 0 || d.Steps != nil || d.SleepHours != nil || d.StressAvg != nil ||
			d.ExerciseMinutes > 0 {
			return true
		}
	}
	return false
}

func (p *period) setting(key string, fallback float64) float64 {
	if v, ok := p.settings[key]; ok {
		return v
	}
	return fallback
}

// --- Health Score ---
// Provisional formula (open question 4 in the brief). Each part is 0-100; the score is their weighted
// average using the health_weight_* rows in app_defaults, over the parts that have data that day.

type DayScore struct {
	Date      string   `json:"date"`
	Score     *float64 `json:"score"`
	Nutrition *float64 `json:"nutrition"`
	Sleep     *float64 `json:"sleep"`
	Stress    *float64 `json:"stress"`
	Exercise  *float64 `json:"exercise"`
}

func (p *period) scoreDay(d DayStats) DayScore {
	s := DayScore{Date: d.Date}
	clamp := func(v float64) float64 { return math.Max(0, math.Min(100, v)) }
	ratio := func(v, target float64) float64 { return math.Min(v/target, 1) }
	ptr := func(v float64) *float64 { v = math.Round(clamp(v)); return &v }

	if t := p.targets; t != nil && d.CaloriesIn > 0 {
		closeness := 1 - math.Min(math.Abs(d.CaloriesIn/t.EnergyKcal-1), 1)
		s.Nutrition = ptr((ratio(d.ProteinG, t.ProteinG) + ratio(d.FiberG, t.FiberG) + closeness) / 3 * 100)
	}
	if d.SleepHours != nil && p.targets != nil && p.targets.SleepHoursMin != nil && p.targets.SleepHoursMax != nil {
		h, lo, hi := *d.SleepHours, *p.targets.SleepHoursMin, *p.targets.SleepHoursMax
		switch {
		case h < lo:
			s.Sleep = ptr(100 - (lo-h)*25)
		case h > hi:
			s.Sleep = ptr(100 - (h-hi)*15)
		default:
			s.Sleep = ptr(100)
		}
	}
	if d.StressAvg != nil {
		s.Stress = ptr((10 - *d.StressAvg) / 9 * 100)
	}
	minutes := ratio(float64(d.ExerciseMinutes), p.setting("exercise_minutes_target", 30))
	if d.Steps != nil && p.targets != nil && p.targets.StepsTarget > 0 {
		s.Exercise = ptr((0.6*ratio(float64(*d.Steps), float64(p.targets.StepsTarget)) + 0.4*minutes) * 100)
	} else if d.ExerciseMinutes > 0 {
		s.Exercise = ptr(minutes * 100)
	}

	var sum, weights float64
	for _, part := range []struct {
		v   *float64
		key string
	}{{s.Nutrition, "nutrition"}, {s.Sleep, "sleep"}, {s.Stress, "stress"}, {s.Exercise, "exercise"}} {
		if part.v != nil {
			w := p.setting("health_weight_"+part.key, 25)
			sum += *part.v * w
			weights += w
		}
	}
	if weights > 0 {
		s.Score = ptr(sum / weights)
	}
	return s
}

func (p *period) scores(days []DayStats) []DayScore {
	out := make([]DayScore, len(days))
	for i, d := range days {
		out[i] = p.scoreDay(d)
	}
	return out
}

type scoreSummary struct {
	Latest        *float64 `json:"latest"`      // most recent day with a score
	LatestDate    *string  `json:"latest_date"` // that day
	Average       *float64 `json:"average"`
	ChangePercent *float64 `json:"change_percent"` // average vs the previous period
	Balance       balance  `json:"balance"`        // average of each part, for the radar chart
}

type balance struct {
	Nutrition *float64 `json:"nutrition"`
	Sleep     *float64 `json:"sleep"`
	Stress    *float64 `json:"stress"`
	Exercise  *float64 `json:"exercise"`
}

func summarizeScores(now, prev []DayScore) scoreSummary {
	var out scoreSummary
	collect := func(list []DayScore, get func(DayScore) *float64) []float64 {
		var v []float64
		for _, d := range list {
			if x := get(d); x != nil {
				v = append(v, *x)
			}
		}
		return v
	}
	score := func(d DayScore) *float64 { return d.Score }
	for i := len(now) - 1; i >= 0; i-- {
		if now[i].Score != nil {
			out.Latest, out.LatestDate = now[i].Score, &now[i].Date
			break
		}
	}
	out.Average = roundPtr(mean(collect(now, score)))
	out.ChangePercent = percentChange(mean(collect(now, score)), mean(collect(prev, score)))
	out.Balance = balance{
		Nutrition: roundPtr(mean(collect(now, func(d DayScore) *float64 { return d.Nutrition }))),
		Sleep:     roundPtr(mean(collect(now, func(d DayScore) *float64 { return d.Sleep }))),
		Stress:    roundPtr(mean(collect(now, func(d DayScore) *float64 { return d.Stress }))),
		Exercise:  roundPtr(mean(collect(now, func(d DayScore) *float64 { return d.Exercise }))),
	}
	return out
}

func roundPtr(v *float64) *float64 {
	if v == nil {
		return nil
	}
	r := math.Round(*v)
	return &r
}

// activityLevel turns average steps and exercise days into Low / Moderate / High for Home and the AI Coach.
func (p *period) activityLevel() *string {
	if p.now.Steps == nil && p.now.ExerciseDays == 0 {
		return nil
	}
	level := "Low"
	stepsRatio := 0.0
	if p.now.Steps != nil && p.targets != nil && p.targets.StepsTarget > 0 {
		stepsRatio = *p.now.Steps / float64(p.targets.StepsTarget)
	}
	switch {
	case stepsRatio >= 1 || p.now.ExerciseDays >= 5:
		level = "High"
	case stepsRatio >= 0.6 || p.now.ExerciseDays >= 3:
		level = "Moderate"
	}
	return &level
}

// --- tips (Package 7A) ---

type Tip struct {
	ID         string `json:"id"`
	Topic      string `json:"topic"`
	TriggerKey string `json:"trigger_key"`
	Text       string `json:"text"`
}

// tipPriority lists trigger keys from most to least important; safety-related stress tips come first.
var tipPriority = []string{
	"high_stress_today", "high_stress_3_days", "sleep_drop_gt_1h", "sleep_below_min_last_night",
	"protein_below_target_4_days", "protein_below_70_today", "fried_snacks_3_days", "no_vegetables_today",
	"calories_over_110_today", "water_below_50_today", "steps_below_50_today", "no_exercise_3_days",
	"stress_lower_on_exercise", "exercise_5_days", "water_target_reached",
}

// triggers says which tip trigger_keys are true for the period's last day and the period as a whole.
func (p *period) triggers() map[string]bool {
	t, today := p.targets, p.last()
	on := map[string]bool{}
	if !p.hasData() {
		return on
	}
	if p.now.SleepHours != nil && p.prev.SleepHours != nil && *p.now.SleepHours-*p.prev.SleepHours <= -1 {
		on["sleep_drop_gt_1h"] = true
	}
	if t != nil && t.SleepHoursMin != nil && today.SleepHours != nil && *today.SleepHours < *t.SleepHoursMin {
		on["sleep_below_min_last_night"] = true
	}
	on["fried_snacks_3_days"] = p.friedSnackDays >= 3
	on["no_vegetables_today"] = today.CaloriesIn > 0 && !p.vegetablesOnLastDay
	if t != nil {
		on["calories_over_110_today"] = today.CaloriesIn > 1.1*t.EnergyKcal
		on["protein_below_70_today"] = today.CaloriesIn > 0 && today.ProteinG < 0.7*t.ProteinG
		on["protein_below_target_4_days"] = p.proteinBelowDays() >= 4
		on["water_below_50_today"] = today.WaterMl < 0.5*t.WaterMl
		on["water_target_reached"] = today.WaterMl >= t.WaterMl
		on["steps_below_50_today"] = today.Steps != nil && float64(*today.Steps) < 0.5*float64(t.StepsTarget)
	}
	recent := untilToday(p.days)
	if n := len(recent); n >= 3 {
		on["no_exercise_3_days"] = recent[n-1].ExerciseMinutes == 0 && recent[n-2].ExerciseMinutes == 0 &&
			recent[n-3].ExerciseMinutes == 0
	}
	on["exercise_5_days"] = p.now.ExerciseDays >= 5
	on["high_stress_today"] = today.StressAvg != nil && *today.StressAvg >= 7
	on["high_stress_3_days"] = p.now.HighStressDays >= 3
	on["stress_lower_on_exercise"] = p.now.StressExerciseDay != nil && p.now.StressRestDay != nil &&
		*p.now.StressExerciseDay < *p.now.StressRestDay
	return on
}

// proteinBelowDays counts days with meals logged where protein stayed under the daily target.
func (p *period) proteinBelowDays() int {
	if p.targets == nil {
		return 0
	}
	n := 0
	for _, d := range untilToday(p.days) {
		if d.CaloriesIn > 0 && d.ProteinG < p.targets.ProteinG {
			n++
		}
	}
	return n
}

// matchingTips returns the tips whose trigger is true, most important first, in the user's language.
func (s *Server) matchingTips(ctx context.Context, p *period) ([]Tip, error) {
	rows, err := s.db.Query(ctx, `
		SELECT id, topic, trigger_key, CASE WHEN $1 = 'en' THEN COALESCE(tip_text_en, tip_text) ELSE tip_text END
		FROM coach_tips WHERE trigger_key IS NOT NULL`, p.user.Language)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	byKey := map[string][]Tip{}
	for rows.Next() {
		var t Tip
		if err := rows.Scan(&t.ID, &t.Topic, &t.TriggerKey, &t.Text); err != nil {
			return nil, err
		}
		byKey[t.TriggerKey] = append(byKey[t.TriggerKey], t)
	}
	if err := rows.Err(); err != nil {
		return nil, err
	}

	on := p.triggers()
	tips := []Tip{}
	for _, key := range tipPriority {
		if on[key] {
			tips = append(tips, byKey[key]...)
		}
	}
	return tips, nil
}

// --- sentences (insight_templates) ---

type templates map[string]string

func (s *Server) loadTemplates(ctx context.Context, language string) (templates, error) {
	rows, err := s.db.Query(ctx, `
		SELECT trigger_key, CASE WHEN $1 = 'en' THEN COALESCE(template_text_en, template_text) ELSE template_text END
		FROM insight_templates`, language)
	if err != nil {
		return nil, err
	}
	defer rows.Close()
	t := templates{}
	for rows.Next() {
		var k, v string
		if err := rows.Scan(&k, &v); err != nil {
			return nil, err
		}
		t[k] = v
	}
	return t, rows.Err()
}

// fill replaces {name} placeholders; it returns "" when the template is missing so callers can skip it.
func (t templates) fill(key string, values map[string]any) string {
	text, ok := t[key]
	if !ok {
		return ""
	}
	for k, v := range values {
		text = strings.ReplaceAll(text, "{"+k+"}", fmtNumber(v))
	}
	return text
}

func fmtNumber(v any) string {
	switch n := v.(type) {
	case float64:
		if n == math.Trunc(n) {
			return fmt.Sprintf("%.0f", n)
		}
		return fmt.Sprintf("%.1f", n)
	case int:
		return fmt.Sprintf("%d", n)
	default:
		return fmt.Sprint(v)
	}
}

// insightSentences are the AI Insights lines on Analytics, strongest signal first.
func (p *period) insightSentences(t templates) []string {
	var out []string
	add := func(s string) {
		if s != "" {
			out = append(out, s)
		}
	}
	if pct := percentChange(p.now.StressExerciseDay, p.now.StressRestDay); pct != nil && *pct < 0 {
		add(t.fill("stress_lower_on_exercise_days", map[string]any{"percent": -*pct}))
	}
	if p.now.SleepHours != nil && p.prev.SleepHours != nil {
		if diff := round1(*p.prev.SleepHours - *p.now.SleepHours); diff >= 0.5 {
			add(t.fill("sleep_drop_vs_last_week", map[string]any{"hours": diff}))
		}
	}
	if n := p.proteinBelowDays(); n >= 3 {
		add(t.fill("protein_below_target_days", map[string]any{"days": n}))
	}
	if p.now.HighStressDays >= 2 {
		add(t.fill("high_stress_days", map[string]any{"days": p.now.HighStressDays}))
	}
	if pct := percentChange(p.now.Steps, p.prev.Steps); pct != nil && math.Abs(*pct) >= 10 {
		add(t.fill("steps_change_vs_last_week", map[string]any{"percent": *pct}))
	}
	return out
}

// healthyMealsSentence describes the change in meals labelled Healthy versus the previous period.
func (p *period) healthyMealsSentence(t templates) string {
	now, prev := float64(p.healthyMeals), float64(p.prevHealthyMeals)
	if pct := percentChange(&now, &prev); pct != nil && *pct != 0 {
		if *pct > 0 {
			return t.fill("healthy_meals_up", map[string]any{"percent": *pct})
		}
		return t.fill("healthy_meals_down", map[string]any{"percent": -*pct})
	}
	return t.fill("healthy_meals_count", map[string]any{"count": p.healthyMeals})
}

// weekdayName is used in coach answers such as "Best day: Saturday".
func weekdayName(date, language string) string {
	d, err := time.Parse(dateLayout, date)
	if err != nil {
		return date
	}
	if language == "id" {
		return []string{"Minggu", "Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu"}[d.Weekday()]
	}
	return d.Weekday().String()
}

func componentName(key, language string) string {
	names := map[string][2]string{
		"nutrition": {"Nutrition", "Nutrisi"}, "sleep": {"Sleep", "Tidur"},
		"stress": {"Stress", "Stres"}, "exercise": {"Exercise", "Olahraga"},
	}
	if language == "id" {
		return names[key][1]
	}
	return names[key][0]
}

// weakestPart returns the balance part with the lowest score.
func (b balance) weakestPart() (string, float64, bool) {
	parts := map[string]*float64{"nutrition": b.Nutrition, "sleep": b.Sleep, "stress": b.Stress, "exercise": b.Exercise}
	keys := []string{"nutrition", "sleep", "stress", "exercise"}
	sort.SliceStable(keys, func(i, j int) bool {
		a, c := parts[keys[i]], parts[keys[j]]
		if a == nil || c == nil {
			return c == nil && a != nil
		}
		return *a < *c
	})
	if v := parts[keys[0]]; v != nil {
		return keys[0], *v, true
	}
	return "", 0, false
}
