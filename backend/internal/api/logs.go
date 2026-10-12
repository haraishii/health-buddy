package api

import (
	"net/http"
	"strconv"
	"strings"
	"time"
)

// --- meals ---

type MealLog struct {
	ID           int64     `db:"id" json:"id"`
	LoggedOn     string    `db:"logged_on" json:"logged_on"`
	MealTime     string    `db:"meal_time" json:"meal_time"`
	FoodID       *string   `db:"food_id" json:"food_id"`
	Barcode      *string   `db:"barcode" json:"barcode"`
	Name         string    `db:"name" json:"name"`
	Servings     float64   `db:"servings" json:"servings"`
	CaloriesKcal float64   `db:"calories_kcal" json:"calories_kcal"`
	ProteinG     float64   `db:"protein_g" json:"protein_g"`
	CarbsG       float64   `db:"carbs_g" json:"carbs_g"`
	FatG         float64   `db:"fat_g" json:"fat_g"`
	FiberG       *float64  `db:"fiber_g" json:"fiber_g"`
	SugarG       *float64  `db:"sugar_g" json:"sugar_g"`
	SodiumMg     *float64  `db:"sodium_mg" json:"sodium_mg"`
	CreatedAt    time.Time `db:"created_at" json:"created_at"`
}

// mealSelect reads meal logs from a relation named m (the table, or a CTE of inserted rows).
const mealSelect = `
	SELECT m.id, to_char(m.logged_on, 'YYYY-MM-DD') AS logged_on, m.meal_time, m.food_id, m.barcode,
	       COALESCE(m.custom_name, f.name, p.brand || ' ' || p.product_name) AS name, m.servings,
	       m.calories_kcal, m.protein_g, m.carbs_g, m.fat_g, m.fiber_g, m.sugar_g, m.sodium_mg, m.created_at
	FROM m
	LEFT JOIN foods f ON f.id = m.food_id
	LEFT JOIN packaged_products p ON p.barcode = m.barcode`

// listMeals: GET /api/v1/me/meals?date=2026-10-12
func (s *Server) listMeals(w http.ResponseWriter, r *http.Request, userID int64) {
	day, err := parseDate(r.URL.Query().Get("date"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "date must be YYYY-MM-DD")
		return
	}
	items, err := queryAll[MealLog](r.Context(), s.db, `
		WITH m AS (SELECT * FROM meal_logs WHERE user_id = $1 AND logged_on = $2)`+mealSelect+`
		ORDER BY array_position(ARRAY['breakfast', 'lunch', 'dinner', 'snack'], m.meal_time), m.created_at`,
		userID, day)
	if err != nil {
		serverError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"date": day.Format(dateLayout), "items": items})
}

type customFood struct {
	Name         string   `json:"name"`
	CaloriesKcal float64  `json:"calories_kcal"`
	ProteinG     float64  `json:"protein_g"`
	CarbsG       float64  `json:"carbs_g"`
	FatG         float64  `json:"fat_g"`
	FiberG       *float64 `json:"fiber_g"`
	SugarG       *float64 `json:"sugar_g"`
	SodiumMg     *float64 `json:"sodium_mg"`
}

// createMeal: POST /api/v1/me/meals with exactly one of food_id (Package 1), barcode (Package 2)
// or custom (e.g. an edited Scan Meal photo result). Nutrients are per serving and get multiplied.
func (s *Server) createMeal(w http.ResponseWriter, r *http.Request, userID int64) {
	var in struct {
		Date     string      `json:"date"`
		MealTime string      `json:"meal_time"`
		FoodID   *string     `json:"food_id"`
		Barcode  *string     `json:"barcode"`
		Custom   *customFood `json:"custom"`
		Servings *float64    `json:"servings"`
	}
	if !decode(w, r, &in) {
		return
	}
	day, err := parseDate(in.Date)
	if err != nil {
		writeError(w, http.StatusBadRequest, "date must be YYYY-MM-DD")
		return
	}
	switch in.MealTime {
	case "breakfast", "lunch", "dinner", "snack":
	default:
		writeError(w, http.StatusBadRequest, "meal_time must be breakfast, lunch, dinner or snack")
		return
	}
	servings := 1.0
	if in.Servings != nil {
		servings = *in.Servings
	}
	if servings <= 0 || servings > 20 {
		writeError(w, http.StatusBadRequest, "servings must be above 0 and at most 20")
		return
	}
	given := 0
	for _, set := range []bool{in.FoodID != nil, in.Barcode != nil, in.Custom != nil} {
		if set {
			given++
		}
	}
	if given != 1 {
		writeError(w, http.StatusBadRequest, "send exactly one of food_id, barcode or custom")
		return
	}

	const insertCols = `INSERT INTO meal_logs (user_id, logged_on, meal_time, food_id, barcode, custom_name, servings,
		calories_kcal, protein_g, carbs_g, fat_g, fiber_g, sugar_g, sodium_mg) `
	var insert string
	args := []any{userID, day, in.MealTime, servings}
	switch {
	case in.FoodID != nil:
		insert = insertCols + `SELECT $1, $2, $3, id, NULL, NULL, $4::numeric, calories_kcal * $4::numeric,
			protein_g * $4::numeric, carbs_g * $4::numeric, fat_g * $4::numeric, fiber_g * $4::numeric,
			sugar_g * $4::numeric, sodium_mg * $4::numeric FROM foods WHERE id = $5`
		args = append(args, *in.FoodID)
	case in.Barcode != nil:
		insert = insertCols + `SELECT $1, $2, $3, NULL, barcode, NULL, $4::numeric, calories_kcal * $4::numeric,
			protein_g * $4::numeric, carbs_g * $4::numeric, fat_g * $4::numeric, fiber_g * $4::numeric,
			sugar_g * $4::numeric, sodium_mg * $4::numeric FROM packaged_products WHERE barcode = $5`
		args = append(args, *in.Barcode)
	default:
		c := in.Custom
		c.Name = strings.TrimSpace(c.Name)
		if c.Name == "" || c.CaloriesKcal < 0 || c.ProteinG < 0 || c.CarbsG < 0 || c.FatG < 0 {
			writeError(w, http.StatusBadRequest, "custom needs a name and non-negative nutrients")
			return
		}
		insert = insertCols + `VALUES ($1, $2, $3, NULL, NULL, $5, $4::numeric, $6::numeric * $4::numeric,
			$7::numeric * $4::numeric, $8::numeric * $4::numeric, $9::numeric * $4::numeric,
			$10::numeric * $4::numeric, $11::numeric * $4::numeric, $12::numeric * $4::numeric)`
		args = append(args, c.Name, c.CaloriesKcal, c.ProteinG, c.CarbsG, c.FatG, c.FiberG, c.SugarG, c.SodiumMg)
	}

	item, err := queryOne[MealLog](r.Context(), s.db, `WITH m AS (`+insert+` RETURNING *)`+mealSelect, args...)
	if isNoRows(err) {
		writeError(w, http.StatusNotFound, "food or barcode not found")
		return
	}
	if err != nil {
		serverError(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, item)
}

func (s *Server) deleteMeal(w http.ResponseWriter, r *http.Request, userID int64) {
	s.deleteOwned(w, r, userID, "meal_logs")
}

// deleteOwned deletes row {id} of table only if it belongs to the user.
func (s *Server) deleteOwned(w http.ResponseWriter, r *http.Request, userID int64, table string) {
	id, err := strconv.ParseInt(r.PathValue("id"), 10, 64)
	if err != nil {
		writeError(w, http.StatusBadRequest, "id must be a number")
		return
	}
	tag, err := s.db.Exec(r.Context(), `DELETE FROM `+table+` WHERE id = $1 AND user_id = $2`, id, userID)
	if err != nil {
		serverError(w, err)
		return
	}
	if tag.RowsAffected() == 0 {
		writeError(w, http.StatusNotFound, "not found")
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

// --- exercise ---

type ExerciseLog struct {
	ID           int64     `db:"id" json:"id"`
	LoggedOn     string    `db:"logged_on" json:"logged_on"`
	ActivityID   string    `db:"activity_id" json:"activity_id"`
	ActivityName string    `db:"activity_name" json:"activity_name"`
	Intensity    string    `db:"intensity" json:"intensity"`
	Minutes      int       `db:"minutes" json:"minutes"`
	Met          float64   `db:"met" json:"met"`
	WeightKg     float64   `db:"weight_kg" json:"weight_kg"`
	CaloriesKcal float64   `db:"calories_kcal" json:"calories_kcal"`
	Note         *string   `db:"note" json:"note"`
	CreatedAt    time.Time `db:"created_at" json:"created_at"`
}

const exerciseSelect = `
	SELECT e.id, to_char(e.logged_on, 'YYYY-MM-DD') AS logged_on, e.activity_id, a.activity_name, a.intensity,
	       e.minutes, e.met, e.weight_kg, e.calories_kcal, e.note, e.created_at
	FROM e JOIN activities a ON a.id = e.activity_id`

// listExercises: GET /api/v1/me/exercises?from=&to=
func (s *Server) listExercises(w http.ResponseWriter, r *http.Request, userID int64) {
	from, to, ok := dateRange(w, r)
	if !ok {
		return
	}
	items, err := queryAll[ExerciseLog](r.Context(), s.db, `
		WITH e AS (SELECT * FROM exercise_logs WHERE user_id = $1 AND logged_on BETWEEN $2 AND $3)`+exerciseSelect+`
		ORDER BY e.logged_on, e.created_at`, userID, from, to)
	if err != nil {
		serverError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"items": items})
}

// createExercise: calories burned = MET x body weight (kg) x duration (hours), as in Package 3.
func (s *Server) createExercise(w http.ResponseWriter, r *http.Request, userID int64) {
	var in struct {
		Date       string  `json:"date"`
		ActivityID string  `json:"activity_id"`
		Minutes    int     `json:"minutes"`
		Note       *string `json:"note"`
	}
	if !decode(w, r, &in) {
		return
	}
	day, err := parseDate(in.Date)
	if err != nil {
		writeError(w, http.StatusBadRequest, "date must be YYYY-MM-DD")
		return
	}
	if in.Minutes < 1 || in.Minutes > 600 {
		writeError(w, http.StatusBadRequest, "minutes must be 1 to 600")
		return
	}
	u, err := s.loadUser(r, userID)
	if err != nil {
		serverError(w, err)
		return
	}
	if u.WeightKg == nil {
		writeError(w, http.StatusUnprocessableEntity, "set weight_kg in your profile first; it is needed for calories burned")
		return
	}

	item, err := queryOne[ExerciseLog](r.Context(), s.db, `
		WITH e AS (
			INSERT INTO exercise_logs (user_id, logged_on, activity_id, minutes, met, weight_kg, calories_kcal, note)
			SELECT $1, $2, id, $4::int, met, $5::numeric, round(met * $5::numeric * $4::int / 60.0, 1), $6
			FROM activities WHERE id = $3
			RETURNING *)`+exerciseSelect, userID, day, in.ActivityID, in.Minutes, *u.WeightKg, in.Note)
	if isNoRows(err) {
		writeError(w, http.StatusNotFound, "activity not found")
		return
	}
	if err != nil {
		serverError(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, item)
}

func (s *Server) deleteExercise(w http.ResponseWriter, r *http.Request, userID int64) {
	s.deleteOwned(w, r, userID, "exercise_logs")
}

// --- stress ---

type StressLog struct {
	ID        int64     `db:"id" json:"id"`
	LoggedOn  string    `db:"logged_on" json:"logged_on"`
	Level     int       `db:"level" json:"level"`
	Category  *string   `db:"category" json:"category"`
	FactorIDs []string  `db:"factor_ids" json:"factor_ids"`
	Note      *string   `db:"note" json:"note"`
	CreatedAt time.Time `db:"created_at" json:"created_at"`
}

// stressSelect adds the Low / Medium / High band for the 1-10 level (Package 4B).
const stressSelect = `
	SELECT l.id, to_char(l.logged_on, 'YYYY-MM-DD') AS logged_on, l.level, b.category, l.factor_ids, l.note, l.created_at
	FROM l LEFT JOIN stress_score_bands b ON l.level BETWEEN b.scale_min AND b.scale_max`

func (s *Server) listStress(w http.ResponseWriter, r *http.Request, userID int64) {
	from, to, ok := dateRange(w, r)
	if !ok {
		return
	}
	items, err := queryAll[StressLog](r.Context(), s.db, `
		WITH l AS (SELECT * FROM stress_logs WHERE user_id = $1 AND logged_on BETWEEN $2 AND $3)`+stressSelect+`
		ORDER BY l.logged_on, l.created_at`, userID, from, to)
	if err != nil {
		serverError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"items": items})
}

func (s *Server) createStress(w http.ResponseWriter, r *http.Request, userID int64) {
	var in struct {
		Date      string   `json:"date"`
		Level     int      `json:"level"`
		FactorIDs []string `json:"factor_ids"`
		Note      *string  `json:"note"`
	}
	if !decode(w, r, &in) {
		return
	}
	day, err := parseDate(in.Date)
	if err != nil {
		writeError(w, http.StatusBadRequest, "date must be YYYY-MM-DD")
		return
	}
	if in.Level < 1 || in.Level > 10 {
		writeError(w, http.StatusBadRequest, "level must be 1 to 10")
		return
	}
	if in.FactorIDs == nil {
		in.FactorIDs = []string{}
	}

	var unknown int
	if err := s.db.QueryRow(r.Context(), `
		SELECT count(*) FROM unnest($1::text[]) AS f (id) WHERE NOT EXISTS (SELECT 1 FROM stress_factors s WHERE s.id = f.id)`,
		in.FactorIDs).Scan(&unknown); err != nil {
		serverError(w, err)
		return
	}
	if unknown > 0 {
		writeError(w, http.StatusBadRequest, "unknown factor id; see GET /api/v1/stress/questionnaire")
		return
	}

	item, err := queryOne[StressLog](r.Context(), s.db, `
		WITH l AS (INSERT INTO stress_logs (user_id, logged_on, level, factor_ids, note) VALUES ($1, $2, $3, $4, $5)
		RETURNING *)`+stressSelect, userID, day, in.Level, in.FactorIDs, in.Note)
	if err != nil {
		serverError(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, item)
}

// --- water, sleep, steps ---

// addWater: POST /api/v1/me/water {"amount_ml": 250}. Returns the day's total.
func (s *Server) addWater(w http.ResponseWriter, r *http.Request, userID int64) {
	var in struct {
		Date     string `json:"date"`
		AmountMl *int   `json:"amount_ml"`
	}
	if !decode(w, r, &in) {
		return
	}
	day, err := parseDate(in.Date)
	if err != nil {
		writeError(w, http.StatusBadRequest, "date must be YYYY-MM-DD")
		return
	}
	amount := 250
	if in.AmountMl != nil {
		amount = *in.AmountMl
	}
	if amount < 1 || amount > 5000 {
		writeError(w, http.StatusBadRequest, "amount_ml must be 1 to 5000")
		return
	}

	var total int
	err = s.db.QueryRow(r.Context(), `
		WITH ins AS (INSERT INTO water_logs (user_id, logged_on, amount_ml) VALUES ($1, $2, $3) RETURNING amount_ml)
		SELECT COALESCE((SELECT sum(amount_ml) FROM water_logs WHERE user_id = $1 AND logged_on = $2), 0)
		     + (SELECT amount_ml FROM ins)`, userID, day, amount).Scan(&total)
	if err != nil {
		serverError(w, err)
		return
	}
	writeJSON(w, http.StatusCreated, map[string]any{"date": day.Format(dateLayout), "total_ml": total})
}

// putSleep: PUT /api/v1/me/sleep/2026-10-12 {"hours": 7.5}. The date is the morning the night ended.
func (s *Server) putSleep(w http.ResponseWriter, r *http.Request, userID int64) {
	day, err := time.Parse(dateLayout, r.PathValue("date"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "date must be YYYY-MM-DD")
		return
	}
	var in struct {
		Hours float64 `json:"hours"`
	}
	if !decode(w, r, &in) {
		return
	}
	if in.Hours < 0 || in.Hours > 24 {
		writeError(w, http.StatusBadRequest, "hours must be 0 to 24")
		return
	}
	if _, err := s.db.Exec(r.Context(), `
		INSERT INTO sleep_logs (user_id, sleep_date, hours) VALUES ($1, $2, $3)
		ON CONFLICT (user_id, sleep_date) DO UPDATE SET hours = EXCLUDED.hours, updated_at = now()`,
		userID, day, in.Hours); err != nil {
		serverError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"date": day.Format(dateLayout), "hours": in.Hours})
}

// putSteps: PUT /api/v1/me/steps/2026-10-12 {"steps": 6240}. Each sync replaces the day's total.
func (s *Server) putSteps(w http.ResponseWriter, r *http.Request, userID int64) {
	day, err := time.Parse(dateLayout, r.PathValue("date"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "date must be YYYY-MM-DD")
		return
	}
	var in struct {
		Steps  int    `json:"steps"`
		Source string `json:"source"`
	}
	if !decode(w, r, &in) {
		return
	}
	if in.Steps < 0 || in.Steps > 200000 {
		writeError(w, http.StatusBadRequest, "steps must be 0 to 200000")
		return
	}
	if in.Source == "" {
		in.Source = "health_connect"
	}
	if _, err := s.db.Exec(r.Context(), `
		INSERT INTO step_logs (user_id, step_date, steps, source) VALUES ($1, $2, $3, $4)
		ON CONFLICT (user_id, step_date) DO UPDATE SET steps = EXCLUDED.steps, source = EXCLUDED.source, updated_at = now()`,
		userID, day, in.Steps, in.Source); err != nil {
		serverError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"date": day.Format(dateLayout), "steps": in.Steps})
}
