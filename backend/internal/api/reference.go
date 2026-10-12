package api

import (
	"context"
	"net/http"
	"strconv"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

// queryAll runs sql and scans every row into T by matching column names to `db` tags.
func queryAll[T any](ctx context.Context, db *pgxpool.Pool, sql string, args ...any) ([]T, error) {
	rows, err := db.Query(ctx, sql, args...)
	if err != nil {
		return nil, err
	}
	return pgx.CollectRows(rows, pgx.RowToStructByName[T])
}

// queryOne is queryAll for exactly one row; it returns pgx.ErrNoRows when there is none.
func queryOne[T any](ctx context.Context, db *pgxpool.Pool, sql string, args ...any) (T, error) {
	rows, err := db.Query(ctx, sql, args...)
	if err != nil {
		var zero T
		return zero, err
	}
	return pgx.CollectOneRow(rows, pgx.RowToStructByName[T])
}

type Food struct {
	ID            string   `db:"id" json:"id"`
	Name          string   `db:"name" json:"name"`
	NameEn        *string  `db:"name_en" json:"name_en"`
	Aliases       []string `db:"aliases" json:"aliases"`
	Category      string   `db:"category" json:"category"`
	CookingMethod string   `db:"cooking_method" json:"cooking_method"`
	Serving       string   `db:"serving" json:"serving"`
	ServingGrams  float64  `db:"serving_grams" json:"serving_grams"`
	CaloriesKcal  float64  `db:"calories_kcal" json:"calories_kcal"`
	ProteinG      float64  `db:"protein_g" json:"protein_g"`
	CarbsG        float64  `db:"carbs_g" json:"carbs_g"`
	FatG          float64  `db:"fat_g" json:"fat_g"`
	FiberG        float64  `db:"fiber_g" json:"fiber_g"`
	SugarG        *float64 `db:"sugar_g" json:"sugar_g"`
	SodiumMg      *float64 `db:"sodium_mg" json:"sodium_mg"`
	Source        string   `db:"source" json:"source"`
	Notes         *string  `db:"notes" json:"notes"`
	Labels        []string `db:"-" json:"labels"`
}

const foodColumns = `id, name, name_en, aliases, category, cooking_method, serving, serving_grams, calories_kcal,
	protein_g, carbs_g, fat_g, fiber_g, sugar_g, sodium_mg, source, notes`

func (f *Food) nutrients() nutrientValues {
	return nutrientValues{ServingGrams: f.ServingGrams, IsDrink: f.Category == "drink", Values: map[string]*float64{
		"calories_kcal": &f.CaloriesKcal, "protein_g": &f.ProteinG, "carbs_g": &f.CarbsG, "fat_g": &f.FatG,
		"fiber_g": &f.FiberG, "sugar_g": f.SugarG, "sodium_mg": f.SodiumMg,
	}}
}

// searchFoods: GET /api/v1/foods?q=nasi&category=staple&limit=20&offset=0
func (s *Server) searchFoods(w http.ResponseWriter, r *http.Request) {
	q := r.URL.Query()
	limit, offset := 20, 0
	if v, err := strconv.Atoi(q.Get("limit")); err == nil && v > 0 && v <= 100 {
		limit = v
	}
	if v, err := strconv.Atoi(q.Get("offset")); err == nil && v >= 0 {
		offset = v
	}
	// Escape LIKE wildcards so "%" in the search box is matched literally.
	term := strings.NewReplacer(`\`, `\\`, `%`, `\%`, `_`, `\_`).Replace(strings.TrimSpace(q.Get("q")))

	foods, err := queryAll[Food](r.Context(), s.db, `
		SELECT `+foodColumns+` FROM foods
		WHERE ($1 = '' OR name ILIKE '%' || $1 || '%' OR name_en ILIKE '%' || $1 || '%'
		       OR EXISTS (SELECT 1 FROM unnest(aliases) AS a WHERE a ILIKE '%' || $1 || '%'))
		  AND ($2 = '' OR category = $2)
		ORDER BY (name ILIKE $1 || '%') DESC, name
		LIMIT $3 OFFSET $4`, term, q.Get("category"), limit, offset)
	if err != nil {
		serverError(w, err)
		return
	}
	if !s.addFoodLabels(w, r, foods) {
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"items": foods, "limit": limit, "offset": offset})
}

func (s *Server) getFood(w http.ResponseWriter, r *http.Request) {
	food, err := queryOne[Food](r.Context(), s.db, `SELECT `+foodColumns+` FROM foods WHERE id = $1`, r.PathValue("id"))
	if isNoRows(err) {
		writeError(w, http.StatusNotFound, "food not found")
		return
	}
	if err != nil {
		serverError(w, err)
		return
	}
	foods := []Food{food}
	if s.addFoodLabels(w, r, foods) {
		writeJSON(w, http.StatusOK, foods[0])
	}
}

func (s *Server) addFoodLabels(w http.ResponseWriter, r *http.Request, foods []Food) bool {
	rules, err := s.labelRules(r.Context())
	if err != nil {
		serverError(w, err)
		return false
	}
	for i := range foods {
		foods[i].Labels = evaluateLabels(rules, foods[i].nutrients())
	}
	return true
}

type Product struct {
	Barcode            string   `db:"barcode" json:"barcode"`
	ProductGroup       string   `db:"product_group" json:"product_group"`
	Brand              string   `db:"brand" json:"brand"`
	ProductName        string   `db:"product_name" json:"product_name"`
	Variant            *string  `db:"variant" json:"variant"`
	PackageSize        string   `db:"package_size" json:"package_size"`
	ServingSize        float64  `db:"serving_size" json:"serving_size"`
	ServingUnit        string   `db:"serving_unit" json:"serving_unit"`
	ServingsPerPackage float64  `db:"servings_per_package" json:"servings_per_package"`
	CaloriesKcal       float64  `db:"calories_kcal" json:"calories_kcal"`
	ProteinG           float64  `db:"protein_g" json:"protein_g"`
	CarbsG             float64  `db:"carbs_g" json:"carbs_g"`
	FatG               float64  `db:"fat_g" json:"fat_g"`
	SugarG             *float64 `db:"sugar_g" json:"sugar_g"`
	FiberG             *float64 `db:"fiber_g" json:"fiber_g"`
	SodiumMg           *float64 `db:"sodium_mg" json:"sodium_mg"`
	PhotoFront         string   `db:"photo_front" json:"photo_front"`
	PhotoLabel         string   `db:"photo_label" json:"photo_label"`
	Notes              *string  `db:"notes" json:"notes"`
	Labels             []string `db:"-" json:"labels"`
}

const productColumns = `barcode, product_group, brand, product_name, variant, package_size, serving_size, serving_unit,
	servings_per_package, calories_kcal, protein_g, carbs_g, fat_g, sugar_g, fiber_g, sodium_mg, photo_front,
	photo_label, notes`

func (p *Product) nutrients() nutrientValues {
	return nutrientValues{ServingGrams: p.ServingSize, IsDrink: p.ServingUnit == "ml", Values: map[string]*float64{
		"calories_kcal": &p.CaloriesKcal, "protein_g": &p.ProteinG, "carbs_g": &p.CarbsG, "fat_g": &p.FatG,
		"fiber_g": p.FiberG, "sugar_g": p.SugarG, "sodium_mg": p.SodiumMg,
	}}
}

// getProduct: GET /api/v1/products/{barcode}, used by Scan Meal (barcode).
func (s *Server) getProduct(w http.ResponseWriter, r *http.Request) {
	p, err := queryOne[Product](r.Context(), s.db,
		`SELECT `+productColumns+` FROM packaged_products WHERE barcode = $1`, r.PathValue("barcode"))
	if isNoRows(err) {
		writeError(w, http.StatusNotFound, "barcode not found")
		return
	}
	if err != nil {
		serverError(w, err)
		return
	}
	rules, err := s.labelRules(r.Context())
	if err != nil {
		serverError(w, err)
		return
	}
	p.Labels = evaluateLabels(rules, p.nutrients())
	writeJSON(w, http.StatusOK, p)
}

type Activity struct {
	ID             string  `db:"id" json:"id"`
	ActivityName   string  `db:"activity_name" json:"activity_name"`
	ActivityNameEn *string `db:"activity_name_en" json:"activity_name_en"`
	Category       string  `db:"category" json:"category"`
	ActivityGroup  string  `db:"activity_group" json:"activity_group"`
	Met            float64 `db:"met" json:"met"`
	Intensity      string  `db:"intensity" json:"intensity"`
	SourceCode     *string `db:"source_code" json:"source_code"`
	Source         string  `db:"source" json:"source"`
	Notes          *string `db:"notes" json:"notes"`
}

// listActivities: GET /api/v1/activities?group=run. Log Exercise picks the row whose
// intensity matches the Light / Moderate / Hard switch.
func (s *Server) listActivities(w http.ResponseWriter, r *http.Request) {
	items, err := queryAll[Activity](r.Context(), s.db, `
		SELECT id, activity_name, activity_name_en, category, activity_group, met, intensity, source_code, source, notes
		FROM activities
		WHERE $1 = '' OR activity_group = $1
		ORDER BY activity_group, met, id`, r.URL.Query().Get("group"))
	if err != nil {
		serverError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"items": items})
}

type stressQuestion struct {
	QuestionID    string `db:"question_id" json:"question_id"`
	TextID        string `db:"text_id" json:"text_id"`
	ReverseScored bool   `db:"reverse_scored" json:"reverse_scored"`
	AnswerOptions string `db:"answer_options" json:"answer_options"`
	Source        string `db:"source" json:"source"`
}

type stressBand struct {
	Category      string  `db:"category" json:"category"`
	ScoreMin      int     `db:"score_min" json:"score_min"`
	ScoreMax      int     `db:"score_max" json:"score_max"`
	ScaleMin      int     `db:"scale_min" json:"scale_min"`
	ScaleMax      int     `db:"scale_max" json:"scale_max"`
	ShortMessage  string  `db:"short_message" json:"short_message"`
	SupportAdvice *string `db:"support_advice" json:"support_advice"`
	Source        string  `db:"source" json:"source"`
}

type stressFactor struct {
	ID     string `db:"id" json:"id"`
	Name   string `db:"name" json:"name"`
	NameEn string `db:"name_en" json:"name_en"`
}

func (s *Server) stressQuestionnaire(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	questions, err := queryAll[stressQuestion](ctx, s.db, `SELECT question_id, text_id, reverse_scored,
		answer_options, source FROM stress_questions ORDER BY question_id`)
	if err != nil {
		serverError(w, err)
		return
	}
	bands, err := queryAll[stressBand](ctx, s.db, `SELECT category, score_min, score_max, scale_min, scale_max,
		short_message, support_advice, source FROM stress_score_bands ORDER BY score_min`)
	if err != nil {
		serverError(w, err)
		return
	}
	factors, err := queryAll[stressFactor](ctx, s.db, `SELECT id, name, name_en FROM stress_factors ORDER BY sort_order`)
	if err != nil {
		serverError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, map[string]any{"questions": questions, "bands": bands, "factors": factors})
}

type coachTip struct {
	ID               string  `db:"id" json:"id"`
	Topic            string  `db:"topic" json:"topic"`
	TriggerCondition string  `db:"trigger_condition" json:"trigger_condition"`
	TipText          string  `db:"tip_text" json:"tip_text"`
	Source           string  `db:"source" json:"source"`
	ReviewedBy       *string `db:"reviewed_by" json:"reviewed_by"`
}

type quickQuestion struct {
	ID             string  `db:"id" json:"id"`
	QuestionText   string  `db:"question_text" json:"question_text"`
	QuestionTextEn *string `db:"question_text_en" json:"question_text_en"`
	Topic          string  `db:"topic" json:"topic"`
	IsDefault      bool    `db:"is_default" json:"is_default"`
}

type restrictedTopic struct {
	ID               string   `db:"id" json:"id"`
	Topic            string   `db:"topic" json:"topic"`
	ExampleQuestions []string `db:"example_questions" json:"example_questions"`
	SafeAnswer       string   `db:"safe_answer" json:"safe_answer"`
	SupportReferral  string   `db:"support_referral" json:"support_referral"`
}

type reminderText struct {
	ID          string `db:"id" json:"id"`
	TimeOfDay   string `db:"time_of_day" json:"time_of_day"`
	Kind        string `db:"kind" json:"kind"`
	MessageText string `db:"message_text" json:"message_text"`
}

type insightTemplate struct {
	ID           string `db:"id" json:"id"`
	Topic        string `db:"topic" json:"topic"`
	TriggerKey   string `db:"trigger_key" json:"trigger_key"`
	TemplateText string `db:"template_text" json:"template_text"`
}

// coachContent: GET /api/v1/coach/content returns all of Package 7 in one call (it is small).
func (s *Server) coachContent(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	var out struct {
		Tips             []coachTip        `json:"tips"`
		QuickQuestions   []quickQuestion   `json:"quick_questions"`
		RestrictedTopics []restrictedTopic `json:"restricted_topics"`
		Reminders        []reminderText    `json:"reminders"`
		InsightTemplates []insightTemplate `json:"insight_templates"`
	}

	var err error
	if out.Tips, err = queryAll[coachTip](ctx, s.db,
		`SELECT id, topic, trigger_condition, tip_text, source, reviewed_by FROM coach_tips ORDER BY id`); err != nil {
		serverError(w, err)
		return
	}
	if out.QuickQuestions, err = queryAll[quickQuestion](ctx, s.db, `SELECT id, question_text, question_text_en,
		topic, is_default FROM coach_quick_questions ORDER BY sort_order`); err != nil {
		serverError(w, err)
		return
	}
	if out.RestrictedTopics, err = queryAll[restrictedTopic](ctx, s.db, `SELECT id, topic, example_questions,
		safe_answer, support_referral FROM coach_restricted_topics ORDER BY id`); err != nil {
		serverError(w, err)
		return
	}
	if out.Reminders, err = queryAll[reminderText](ctx, s.db,
		`SELECT id, time_of_day, kind, message_text FROM reminder_texts ORDER BY id`); err != nil {
		serverError(w, err)
		return
	}
	out.InsightTemplates, err = queryAll[insightTemplate](ctx, s.db,
		`SELECT id, topic, trigger_key, template_text FROM insight_templates ORDER BY id`)
	if err != nil {
		serverError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, out)
}
