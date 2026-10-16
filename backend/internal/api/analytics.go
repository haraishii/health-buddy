package api

import (
	"context"
	"math"
	"net/http"
	"time"
)

// DayStats is one day of a user's data, the building block for Home and Analytics.
type DayStats struct {
	Date            string   `db:"date" json:"date"`
	CaloriesIn      float64  `db:"calories_in" json:"calories_in"`
	ProteinG        float64  `db:"protein_g" json:"protein_g"`
	CarbsG          float64  `db:"carbs_g" json:"carbs_g"`
	FatG            float64  `db:"fat_g" json:"fat_g"`
	FiberG          float64  `db:"fiber_g" json:"fiber_g"`
	SugarG          float64  `db:"sugar_g" json:"sugar_g"`
	SodiumMg        float64  `db:"sodium_mg" json:"sodium_mg"`
	WaterMl         float64  `db:"water_ml" json:"water_ml"`
	Steps           *int     `db:"steps" json:"steps"`
	SleepHours      *float64 `db:"sleep_hours" json:"sleep_hours"`
	StressAvg       *float64 `db:"stress_avg" json:"stress_avg"`
	ExerciseMinutes int      `db:"exercise_minutes" json:"exercise_minutes"`
	CaloriesBurned  float64  `db:"calories_burned" json:"calories_burned"`
}

func (s *Server) dayStats(ctx context.Context, userID int64, from, to time.Time) ([]DayStats, error) {
	return queryAll[DayStats](ctx, s.db, `
		WITH days AS (SELECT d::date AS day FROM generate_series($2::date, $3::date, interval '1 day') AS d),
		meals AS (
			SELECT logged_on, sum(calories_kcal) AS kcal, sum(protein_g) AS protein, sum(carbs_g) AS carbs,
			       sum(fat_g) AS fat, sum(fiber_g) AS fiber, sum(sugar_g) AS sugar, sum(sodium_mg) AS sodium
			FROM meal_logs WHERE user_id = $1 AND logged_on BETWEEN $2 AND $3 GROUP BY logged_on),
		water AS (
			SELECT logged_on, sum(amount_ml) AS ml
			FROM water_logs WHERE user_id = $1 AND logged_on BETWEEN $2 AND $3 GROUP BY logged_on),
		stress AS (
			SELECT logged_on, avg(level)::float8 AS level
			FROM stress_logs WHERE user_id = $1 AND logged_on BETWEEN $2 AND $3 GROUP BY logged_on),
		exercise AS (
			SELECT logged_on, sum(minutes) AS minutes, sum(calories_kcal) AS kcal
			FROM exercise_logs WHERE user_id = $1 AND logged_on BETWEEN $2 AND $3 GROUP BY logged_on)
		SELECT to_char(days.day, 'YYYY-MM-DD') AS date,
		       COALESCE(meals.kcal, 0) AS calories_in, COALESCE(meals.protein, 0) AS protein_g,
		       COALESCE(meals.carbs, 0) AS carbs_g, COALESCE(meals.fat, 0) AS fat_g,
		       COALESCE(meals.fiber, 0) AS fiber_g, COALESCE(meals.sugar, 0) AS sugar_g,
		       COALESCE(meals.sodium, 0) AS sodium_mg, COALESCE(water.ml, 0) AS water_ml,
		       st.steps, sl.hours AS sleep_hours, stress.level AS stress_avg,
		       COALESCE(exercise.minutes, 0)::int AS exercise_minutes, COALESCE(exercise.kcal, 0) AS calories_burned
		FROM days
		LEFT JOIN meals ON meals.logged_on = days.day
		LEFT JOIN water ON water.logged_on = days.day
		LEFT JOIN stress ON stress.logged_on = days.day
		LEFT JOIN exercise ON exercise.logged_on = days.day
		LEFT JOIN step_logs st ON st.user_id = $1 AND st.step_date = days.day
		LEFT JOIN sleep_logs sl ON sl.user_id = $1 AND sl.sleep_date = days.day
		ORDER BY days.day`, userID, from, to)
}

type goalProgress struct {
	Key     string   `json:"key"`
	Current float64  `json:"current"`
	Target  *float64 `json:"target"`
	Unit    string   `json:"unit"`
}

// getSummary: GET /api/v1/me/summary?date= returns everything Home, Food, Profile and the AI Coach header
// need for one day, plus the 7 days ending on it (Health Score, activity level, tip).
func (s *Server) getSummary(w http.ResponseWriter, r *http.Request, userID int64) {
	day, err := parseDate(r.URL.Query().Get("date"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "date must be YYYY-MM-DD")
		return
	}
	ctx := r.Context()
	p, err := s.loadPeriod(ctx, userID, day.AddDate(0, 0, -6), day)
	if err != nil {
		serverError(w, err)
		return
	}
	today := p.last()

	// target reads one goal from the targets; nil when the profile is incomplete or the goal is unknown.
	target := func(get func(*Targets) *float64) *float64 {
		if p.targets == nil {
			return nil
		}
		return get(p.targets)
	}
	ptr := func(v float64) *float64 { return &v }
	steps, sleep := 0.0, 0.0
	if today.Steps != nil {
		steps = float64(*today.Steps)
	}
	if today.SleepHours != nil {
		sleep = *today.SleepHours
	}
	goals := []goalProgress{
		{"steps", steps, target(func(t *Targets) *float64 { return ptr(float64(t.StepsTarget)) }), "steps"},
		{"water", today.WaterMl, target(func(t *Targets) *float64 { return ptr(t.WaterMl) }), "ml"},
		{"protein", today.ProteinG, target(func(t *Targets) *float64 { return ptr(t.ProteinG) }), "g"},
		{"sleep_last_night", sleep, target(func(t *Targets) *float64 { return t.SleepHoursMin }), "h"},
		{"calories", today.CaloriesIn, target(func(t *Targets) *float64 { return ptr(t.EnergyKcal) }), "kcal"},
		{"carbs", today.CarbsG, target(func(t *Targets) *float64 { return ptr(t.CarbsG) }), "g"},
		{"fat", today.FatG, target(func(t *Targets) *float64 { return ptr(t.FatG) }), "g"},
		{"fiber", today.FiberG, target(func(t *Targets) *float64 { return ptr(t.FiberG) }), "g"},
	}

	var latestStress *StressLog
	if items, err := queryAll[StressLog](ctx, s.db, `
		WITH l AS (SELECT * FROM stress_logs WHERE user_id = $1 AND logged_on = $2 ORDER BY created_at DESC LIMIT 1)`+
		stressSelect, userID, day); err != nil {
		serverError(w, err)
		return
	} else if len(items) > 0 {
		latestStress = &items[0]
	}
	// Stress label: today's check-in, otherwise the band of the 7-day average.
	var stressLevel *string
	if latestStress != nil {
		stressLevel = latestStress.Category
	} else if p.now.Stress != nil {
		if stressLevel, err = s.stressBand(ctx, *p.now.Stress); err != nil {
			serverError(w, err)
			return
		}
	}

	tips, err := s.matchingTips(ctx, p)
	if err != nil {
		serverError(w, err)
		return
	}
	var tip *Tip
	if len(tips) > 0 {
		tip = &tips[0]
	}

	writeJSON(w, http.StatusOK, map[string]any{
		"date":           day.Format(dateLayout),
		"user":           p.user,
		"totals":         today,
		"goals":          goals,
		"targets":        p.targets,
		"targets_error":  p.targetsError,
		"latest_stress":  latestStress,
		"stress_level":   stressLevel,
		"activity_level": p.activityLevel(),
		"health_score":   summarizeScores(p.scores(p.days), p.scores(p.prevDays)),
		"week_averages":  p.now,
		"tip":            tip,
	})
}

// stressBand maps a 1-10 level to Low / Medium / High using Package 4B.
func (s *Server) stressBand(ctx context.Context, level float64) (*string, error) {
	var category string
	err := s.db.QueryRow(ctx, `SELECT category FROM stress_score_bands WHERE $1 BETWEEN scale_min AND scale_max`,
		int(math.Round(level))).Scan(&category)
	if isNoRows(err) {
		return nil, nil
	}
	return &category, err
}

type periodAverages struct {
	CaloriesIn        float64  `json:"calories_in"`
	ProteinG          float64  `json:"protein_g"`
	CarbsG            float64  `json:"carbs_g"`
	FatG              float64  `json:"fat_g"`
	FiberG            float64  `json:"fiber_g"`
	WaterMl           float64  `json:"water_ml"`
	Steps             *float64 `json:"steps"`
	SleepHours        *float64 `json:"sleep_hours"`
	Stress            *float64 `json:"stress"`
	CaloriesBurned    float64  `json:"calories_burned"`
	ExerciseMinutes   float64  `json:"exercise_minutes"`
	ExerciseDays      int      `json:"exercise_days"`
	LoggedFoodDays    int      `json:"logged_food_days"`
	StressExerciseDay *float64 `json:"stress_on_exercise_days"`
	StressRestDay     *float64 `json:"stress_on_rest_days"`
	HighStressDays    int      `json:"high_stress_days"`
}

func averages(days []DayStats) periodAverages {
	var a periodAverages
	var steps, sleep, stress, stressEx, stressRest []float64
	for _, d := range days {
		// Nutrition averages only count days with food logged, so a forgotten day does not look like fasting.
		if d.CaloriesIn > 0 {
			a.LoggedFoodDays++
			a.CaloriesIn += d.CaloriesIn
			a.ProteinG += d.ProteinG
			a.CarbsG += d.CarbsG
			a.FatG += d.FatG
			a.FiberG += d.FiberG
		}
		a.WaterMl += d.WaterMl
		a.CaloriesBurned += d.CaloriesBurned
		a.ExerciseMinutes += float64(d.ExerciseMinutes)
		if d.ExerciseMinutes > 0 {
			a.ExerciseDays++
		}
		if d.Steps != nil {
			steps = append(steps, float64(*d.Steps))
		}
		if d.SleepHours != nil {
			sleep = append(sleep, *d.SleepHours)
		}
		if d.StressAvg != nil {
			stress = append(stress, *d.StressAvg)
			if *d.StressAvg >= 7 {
				a.HighStressDays++
			}
			if d.ExerciseMinutes > 0 {
				stressEx = append(stressEx, *d.StressAvg)
			} else {
				stressRest = append(stressRest, *d.StressAvg)
			}
		}
	}
	if n := float64(a.LoggedFoodDays); n > 0 {
		a.CaloriesIn = round1(a.CaloriesIn / n)
		a.ProteinG = round1(a.ProteinG / n)
		a.CarbsG = round1(a.CarbsG / n)
		a.FatG = round1(a.FatG / n)
		a.FiberG = round1(a.FiberG / n)
	}
	if n := float64(len(days)); n > 0 {
		a.WaterMl = round1(a.WaterMl / n)
		a.CaloriesBurned = round1(a.CaloriesBurned / n)
		a.ExerciseMinutes = round1(a.ExerciseMinutes / n)
	}
	a.Steps, a.SleepHours, a.Stress = mean(steps), mean(sleep), mean(stress)
	a.StressExerciseDay, a.StressRestDay = mean(stressEx), mean(stressRest)
	return a
}

func mean(v []float64) *float64 {
	if len(v) == 0 {
		return nil
	}
	sum := 0.0
	for _, x := range v {
		sum += x
	}
	m := round1(sum / float64(len(v)))
	return &m
}

func round1(v float64) float64 { return math.Round(v*10) / 10 }

// percentChange returns (now - before) / before in percent, or nil when either side is missing.
func percentChange(now, before *float64) *float64 {
	if now == nil || before == nil || *before == 0 {
		return nil
	}
	p := math.Round((*now - *before) / *before * 100)
	return &p
}

// getAnalytics: GET /api/v1/me/analytics?from=&to= (default: last 7 days). Compares with the period of the
// same length just before it for the trends, and adds the Health Score and AI Insights sentences.
func (s *Server) getAnalytics(w http.ResponseWriter, r *http.Request, userID int64) {
	from, to, ok := dateRange(w, r)
	if !ok {
		return
	}
	ctx := r.Context()
	p, err := s.loadPeriod(ctx, userID, from, to)
	if err != nil {
		serverError(w, err)
		return
	}
	now, prev := p.now, p.prev

	var sleepDiff *float64
	if now.SleepHours != nil && prev.SleepHours != nil {
		d := round1(*now.SleepHours - *prev.SleepHours)
		sleepDiff = &d
	}

	// Percent of daily target for the Nutrition chart, when the profile allows targets.
	var nutritionPercent map[string]float64
	if t := p.targets; t != nil {
		pct := func(v, target float64) float64 { return math.Round(v / target * 100) }
		nutritionPercent = map[string]float64{
			"calories": pct(now.CaloriesIn, t.EnergyKcal), "protein": pct(now.ProteinG, t.ProteinG),
			"carbs": pct(now.CarbsG, t.CarbsG), "fat": pct(now.FatG, t.FatG), "fiber": pct(now.FiberG, t.FiberG),
			"water": pct(now.WaterMl, t.WaterMl),
		}
	}

	t, err := s.loadTemplates(ctx, p.user.Language)
	if err != nil {
		serverError(w, err)
		return
	}
	tips, err := s.matchingTips(ctx, p)
	if err != nil {
		serverError(w, err)
		return
	}
	var recommendation *string
	if len(tips) > 0 {
		recommendation = &tips[0].Text
	}
	healthyNow, healthyPrev := float64(p.healthyMeals), float64(p.prevHealthyMeals)
	scores := p.scores(p.days)

	writeJSON(w, http.StatusOK, map[string]any{
		"from":              from.Format(dateLayout),
		"to":                to.Format(dateLayout),
		"days":              p.days,
		"scores":            scores,
		"health_score":      summarizeScores(scores, p.scores(p.prevDays)),
		"averages":          now,
		"previous_averages": prev,
		"nutrition_percent": nutritionPercent,
		"vs_previous": map[string]any{
			"sleep_hours_diff":         sleepDiff,
			"steps_change_percent":     percentChange(now.Steps, prev.Steps),
			"stress_change_percent":    percentChange(now.Stress, prev.Stress),
			"exercise_change_percent":  percentChange(&now.ExerciseMinutes, &prev.ExerciseMinutes),
			"healthy_meals_change_pct": percentChange(&healthyNow, &healthyPrev),
		},
		"healthy_meals":          p.healthyMeals,
		"healthy_meals_sentence": p.healthyMealsSentence(t),
		// Numbers for the insight_templates sentences, e.g. IN01 "stress drops {percent}% on exercise days".
		"insights": map[string]any{
			"stress_exercise_vs_rest_percent": percentChange(now.StressExerciseDay, now.StressRestDay),
			"high_stress_days":                now.HighStressDays,
			"exercise_days":                   now.ExerciseDays,
		},
		"insight_sentences": p.insightSentences(t),
		"recommendation":    recommendation,
		"tips":              tips,
	})
}
