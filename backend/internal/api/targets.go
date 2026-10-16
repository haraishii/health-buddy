package api

import (
	"context"
	"errors"
	"net/http"
	"time"
)

var (
	errProfileIncomplete = errors.New("set birth_date and sex in your profile to get daily targets")
	errNoTargets         = errors.New("no nutrition targets for this age; Package 5 covers ages 10 and above")
)

type intakeLimit struct {
	Nutrient   string  `db:"nutrient" json:"nutrient"`
	DailyLimit float64 `db:"daily_limit" json:"daily_limit"`
	Unit       string  `db:"unit" json:"unit"`
	Source     string  `db:"source" json:"source"`
}

// Targets are the user's daily goals, picked from Package 5 by age, sex and life stage.
type Targets struct {
	Group                  string        `json:"group"`
	LifeStage              string        `json:"life_stage"`
	EnergyKcal             float64       `json:"energy_kcal"`
	ProteinG               float64       `json:"protein_g"`
	FatG                   float64       `json:"fat_g"`
	CarbsG                 float64       `json:"carbs_g"`
	FiberG                 float64       `json:"fiber_g"`
	WaterMl                float64       `json:"water_ml"`
	SleepHoursMin          *float64      `json:"sleep_hours_min"`
	SleepHoursMax          *float64      `json:"sleep_hours_max"`
	StepsTarget            int           `json:"steps_target"`
	ActivityRecommendation *string       `json:"activity_recommendation"`
	Limits                 []intakeLimit `json:"limits"`
	Sources                []string      `json:"sources"`
}

func (s *Server) targetsFor(ctx context.Context, u User) (Targets, error) {
	if u.BirthDate == nil || u.Sex == nil {
		return Targets{}, errProfileIncomplete
	}
	birth, _ := time.Parse(dateLayout, *u.BirthDate)
	age := ageOn(birth, time.Now())
	t := Targets{LifeStage: u.LifeStage}

	var source string
	err := s.db.QueryRow(ctx, `
		SELECT group_name, energy_kcal, protein_g, fat_g, carbs_g, fiber_g, water_ml, source
		FROM nutrition_targets
		WHERE life_stage = 'general' AND sex = $1 AND $2 BETWEEN age_min AND COALESCE(age_max, 200)`,
		*u.Sex, age).Scan(&t.Group, &t.EnergyKcal, &t.ProteinG, &t.FatG, &t.CarbsG, &t.FiberG, &t.WaterMl, &source)
	if isNoRows(err) {
		return t, errNoTargets
	}
	if err != nil {
		return t, err
	}
	t.Sources = append(t.Sources, source)

	// AKG lists pregnancy and breastfeeding needs as additions to the woman's age group.
	if u.LifeStage != "general" {
		var add Targets
		err := s.db.QueryRow(ctx, `
			SELECT group_name, energy_kcal, protein_g, fat_g, carbs_g, fiber_g, water_ml, source
			FROM nutrition_targets WHERE life_stage = $1 AND values_are_additions`, u.LifeStage).
			Scan(&add.Group, &add.EnergyKcal, &add.ProteinG, &add.FatG, &add.CarbsG, &add.FiberG, &add.WaterMl, &source)
		if err != nil && !isNoRows(err) {
			return t, err
		}
		if err == nil {
			t.Group += " + " + add.Group
			t.EnergyKcal += add.EnergyKcal
			t.ProteinG += add.ProteinG
			t.FatG += add.FatG
			t.CarbsG += add.CarbsG
			t.FiberG += add.FiberG
			t.WaterMl += add.WaterMl
			t.Sources = append(t.Sources, source)
		}
	}

	err = s.db.QueryRow(ctx, `
		SELECT sleep_hours_min, sleep_hours_max, source FROM sleep_recommendations
		WHERE $1 BETWEEN age_min AND COALESCE(age_max, 200) ORDER BY age_min DESC LIMIT 1`, age).
		Scan(&t.SleepHoursMin, &t.SleepHoursMax, &source)
	if err != nil && !isNoRows(err) {
		return t, err
	}
	if err == nil {
		t.Sources = append(t.Sources, source)
	}

	err = s.db.QueryRow(ctx, `
		SELECT recommendation FROM activity_recommendations
		WHERE $1 BETWEEN age_min AND COALESCE(age_max, 200) ORDER BY age_min DESC LIMIT 1`, age).
		Scan(&t.ActivityRecommendation)
	if err != nil && !isNoRows(err) {
		return t, err
	}

	if err := s.db.QueryRow(ctx, `
		SELECT COALESCE($1::int, (SELECT value::int FROM app_defaults WHERE key = 'steps_target'), 0)`,
		u.StepsTarget).Scan(&t.StepsTarget); err != nil {
		return t, err
	}

	t.Limits, err = queryAll[intakeLimit](ctx, s.db,
		`SELECT nutrient, daily_limit, unit, source FROM daily_intake_limits ORDER BY nutrient`)
	return t, err
}

func (s *Server) getTargets(w http.ResponseWriter, r *http.Request, userID int64) {
	u, err := s.loadUser(r, userID)
	if err != nil {
		serverError(w, err)
		return
	}
	t, err := s.targetsFor(r.Context(), u)
	if err != nil {
		if errors.Is(err, errProfileIncomplete) || errors.Is(err, errNoTargets) {
			writeError(w, http.StatusUnprocessableEntity, err.Error())
			return
		}
		serverError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, t)
}
