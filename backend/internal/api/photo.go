package api

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"math"
	"net/http"
	"regexp"
	"strings"
	"time"
	"unicode"

	"github.com/iwinardhyas/health-buddy/backend/internal/ollama"
)

// Scan Meal photos. A vision model names each food, estimates its weight and nutrients and where it is in the photo.
// When a name is exactly one food in the foods table, that food's nutrients are used instead of the model's.
// Nothing is saved here: the app shows the result for review and saves it with POST /me/meals/batch.

// photoPrompt was tested on gemma4:31b with Indonesian dishes (design doc, Appendix A).
const photoPrompt = `You are the food recognition step of an Indonesian nutrition app.
List every distinct food item visible in the photo (for example: nasi putih, ayam goreng, sambal, tumis kangkung, telur).
Ignore the plate, cutlery, table and drinks unless they are food.
For each item give:
- name_id: Indonesian name, name_en: English name
- grams: estimated weight of the visible portion (a dinner plate is about 25 cm wide; a scoop of rice is about 100-150 g)
- kcal, protein_g, carbs_g, fat_g, fiber_g for that weight
- confidence: 0 to 1
- box_2d: [y_min, x_min, y_max, x_max] as integers from 0 to 1000, relative to the image height and width
- mixed: true if it is mixed into or covered by other food so it cannot be cut out cleanly
Put anything you see but cannot identify in "unrecognized" as a short description.
Answer with only a JSON object: {"items": [...], "unrecognized": [...]}`

const (
	maxPhotoItems = 20
	maxPhotoGrams = 2000
	maxPhotoBytes = 4 << 20 // decoded image
	maxPhotoBody  = 6 << 20 // JSON body with the base64 image
)

var (
	errPhotoUnavailable = errors.New("photo model unavailable") // not in the plan, rate limited or down
	errPhotoTimeout     = errors.New("photo analysis timed out")
	errPhotoFailed      = errors.New("photo analysis failed")
	errBadPhoto         = errors.New("image must be a base64 JPEG or PNG under 4 MB")
)

// photoBox is where a food is in the photo, from 0 to 1000 of the width (x) and height (y).
type photoBox struct {
	XMin int `json:"x_min"`
	YMin int `json:"y_min"`
	XMax int `json:"x_max"`
	YMax int `json:"y_max"`
}

type photoItem struct {
	Name         string    `json:"name"`
	NameEn       string    `json:"name_en"`
	NameID       string    `json:"-"` // the model's Indonesian name, kept for matching after Name is replaced
	Grams        float64   `json:"grams"`
	CaloriesKcal float64   `json:"calories_kcal"`
	ProteinG     float64   `json:"protein_g"`
	CarbsG       float64   `json:"carbs_g"`
	FatG         float64   `json:"fat_g"`
	FiberG       float64   `json:"fiber_g"`
	Confidence   float64   `json:"confidence"`
	Box          *photoBox `json:"box"`
	Source       string    `json:"source"` // database or ai
	FoodID       *string   `json:"food_id"`
	ServingGrams *float64  `json:"serving_grams"`
}

type photoResult struct {
	Model        string      `json:"model"`
	Items        []photoItem `json:"items"`
	Unrecognized []string    `json:"unrecognized"`
}

// analyzeMealPhoto: POST /api/v1/me/meals/photo {"image": "<base64 JPEG or PNG>"}. Saves nothing.
func (s *Server) analyzeMealPhoto(w http.ResponseWriter, r *http.Request, _ int64) {
	var in struct {
		Image string `json:"image"`
	}
	if !decodeLimit(w, r, &in, maxPhotoBody) {
		return
	}
	if err := checkPhotoImage(in.Image); err != nil {
		writeError(w, http.StatusBadRequest, err.Error())
		return
	}
	if s.vision == nil {
		writeError(w, http.StatusServiceUnavailable, "photo recognition is not configured")
		return
	}
	// The model can take longer than the server's default write timeout.
	if err := http.NewResponseController(w).SetWriteDeadline(time.Now().Add(s.cfg.OllamaVisionTimeout + 15*time.Second)); err != nil {
		log.Printf("photo meal: extend write deadline: %v", err)
	}

	res, err := s.recognizeMeal(r.Context(), in.Image)
	if err != nil {
		log.Printf("photo meal: %v", err)
		switch {
		case errors.Is(err, errPhotoUnavailable):
			writeError(w, http.StatusServiceUnavailable, "AI is unavailable right now. Add the food manually.")
		case errors.Is(err, errPhotoTimeout):
			writeError(w, http.StatusGatewayTimeout, "Photo analysis took too long. Try again or add the food manually.")
		default:
			writeError(w, http.StatusBadGateway, "Photo analysis failed. Try again or add the food manually.")
		}
		return
	}
	if len(res.Items) > 0 {
		foods, err := s.foodCandidates(r.Context(), res.Items)
		if err != nil {
			serverError(w, err)
			return
		}
		res.Items = pickMatches(res.Items, foods)
	}
	writeJSON(w, http.StatusOK, res)
}

// recognizeMeal asks the vision model about one photo. It is the single entry point for photo analysis,
// so a per-user daily limit can be added here later.
func (s *Server) recognizeMeal(ctx context.Context, imageB64 string) (photoResult, error) {
	ctx, cancel := context.WithTimeout(ctx, s.cfg.OllamaVisionTimeout)
	defer cancel()
	answer, err := s.vision.ChatWith(ctx, ollama.Request{
		Messages:    []ollama.Message{{Role: "user", Content: photoPrompt, Images: []string{imageB64}}},
		Think:       false,
		Temperature: 0.2,
		NumPredict:  2048,
	})
	var se *ollama.StatusError
	switch {
	case errors.As(err, &se) && (se.StatusCode == http.StatusPaymentRequired ||
		se.StatusCode == http.StatusTooManyRequests || se.StatusCode == http.StatusServiceUnavailable):
		return photoResult{}, fmt.Errorf("%w: %v", errPhotoUnavailable, err)
	case err != nil && (errors.Is(err, context.DeadlineExceeded) || errors.Is(ctx.Err(), context.DeadlineExceeded)):
		return photoResult{}, fmt.Errorf("%w: %v", errPhotoTimeout, err)
	case err != nil:
		return photoResult{}, fmt.Errorf("%w: %v", errPhotoFailed, err)
	}

	items, unrecognized, err := parsePhotoAnswer(answer)
	if err != nil {
		return photoResult{}, fmt.Errorf("%w: %v (answer starts %q)", errPhotoFailed, err, truncateRunes(answer, 120))
	}
	return photoResult{Model: s.vision.Model, Items: items, Unrecognized: unrecognized}, nil
}

// checkPhotoImage accepts a base64 JPEG or PNG of at most 4 MB.
func checkPhotoImage(b64 string) error {
	if b64 == "" || base64.StdEncoding.DecodedLen(len(b64)) > maxPhotoBytes+3 {
		return errBadPhoto
	}
	data, err := base64.StdEncoding.DecodeString(b64)
	if err != nil || len(data) > maxPhotoBytes {
		return errBadPhoto
	}
	if !bytes.HasPrefix(data, []byte{0xFF, 0xD8, 0xFF}) && !bytes.HasPrefix(data, []byte{0x89, 'P', 'N', 'G'}) {
		return errBadPhoto
	}
	return nil
}

// rawPhotoItem is one food as the model writes it. gemma4 ignores the JSON schema, so names and box shapes vary.
type rawPhotoItem struct {
	NameID       string          `json:"name_id"`
	Name         string          `json:"name"`
	NameEn       string          `json:"name_en"`
	Grams        float64         `json:"grams"`
	Kcal         float64         `json:"kcal"`
	CaloriesKcal float64         `json:"calories_kcal"`
	ProteinG     float64         `json:"protein_g"`
	CarbsG       float64         `json:"carbs_g"`
	FatG         float64         `json:"fat_g"`
	FiberG       float64         `json:"fiber_g"`
	Confidence   float64         `json:"confidence"`
	Box2D        json.RawMessage `json:"box_2d"`
	Box          json.RawMessage `json:"box"`
}

var fencedJSON = regexp.MustCompile("(?s)```(?:json)?\\s*(.*?)```")

// parsePhotoAnswer reads the model's answer: a JSON object {items, unrecognized} or a bare list of items,
// optionally inside a ``` fence. Items without a name or with an impossible weight are dropped.
func parsePhotoAnswer(content string) ([]photoItem, []string, error) {
	text := strings.TrimSpace(content)
	if m := fencedJSON.FindStringSubmatch(text); m != nil {
		text = m[1]
	} else if strings.HasPrefix(text, "```") { // fence that was never closed
		_, text, _ = strings.Cut(text, "\n")
	}
	text = strings.TrimSpace(text)

	var rawItems []rawPhotoItem
	unrecognized := []string{}
	if strings.HasPrefix(text, "[") {
		if err := json.Unmarshal([]byte(text), &rawItems); err != nil {
			return nil, nil, fmt.Errorf("model answer is not a JSON list: %w", err)
		}
	} else {
		var obj struct {
			Items        []rawPhotoItem `json:"items"`
			Unrecognized []string       `json:"unrecognized"`
		}
		if err := json.Unmarshal([]byte(text), &obj); err != nil {
			return nil, nil, fmt.Errorf("model answer is not JSON: %w", err)
		}
		rawItems = obj.Items
		if obj.Unrecognized != nil {
			unrecognized = obj.Unrecognized
		}
	}

	items := []photoItem{}
	for _, r := range rawItems {
		name := strings.TrimSpace(r.NameID)
		if name == "" {
			name = strings.TrimSpace(r.Name)
		}
		if name == "" || r.Grams <= 0 || r.Grams > maxPhotoGrams {
			continue
		}
		if len(items) == maxPhotoItems {
			break
		}
		kcal := r.Kcal
		if kcal == 0 {
			kcal = r.CaloriesKcal
		}
		box := parseBox(r.Box2D)
		if box == nil {
			box = parseBox(r.Box)
		}
		items = append(items, photoItem{
			Name: name, NameID: name, NameEn: strings.TrimSpace(r.NameEn), Grams: round1(r.Grams),
			CaloriesKcal: nonNeg(kcal), ProteinG: nonNeg(r.ProteinG), CarbsG: nonNeg(r.CarbsG), FatG: nonNeg(r.FatG),
			FiberG: nonNeg(r.FiberG), Confidence: math.Min(math.Max(r.Confidence, 0), 1), Box: box, Source: "ai",
		})
	}
	return items, unrecognized, nil
}

// parseBox reads [y_min, x_min, y_max, x_max] (Gemma's order) or {x_min, y_min, x_max, y_max}, clamped to 0..1000.
// An empty or zero-area box is nil.
func parseBox(raw json.RawMessage) *photoBox {
	if len(raw) == 0 || string(raw) == "null" {
		return nil
	}
	var yMin, xMin, yMax, xMax float64
	var list []float64
	var obj struct {
		XMin float64 `json:"x_min"`
		YMin float64 `json:"y_min"`
		XMax float64 `json:"x_max"`
		YMax float64 `json:"y_max"`
	}
	switch {
	case json.Unmarshal(raw, &list) == nil && len(list) == 4:
		yMin, xMin, yMax, xMax = list[0], list[1], list[2], list[3]
	case json.Unmarshal(raw, &obj) == nil:
		yMin, xMin, yMax, xMax = obj.YMin, obj.XMin, obj.YMax, obj.XMax
	default:
		return nil
	}
	clamp := func(v float64) int { return int(math.Round(math.Min(math.Max(v, 0), 1000))) }
	b := photoBox{XMin: clamp(xMin), YMin: clamp(yMin), XMax: clamp(xMax), YMax: clamp(yMax)}
	if b.XMax <= b.XMin || b.YMax <= b.YMin {
		return nil
	}
	return &b
}

func nonNeg(v float64) float64 { return round1(math.Max(v, 0)) }

// normalizeFoodName lowercases, collapses whitespace and trims surrounding punctuation: "  Nasi  Putih. " → "nasi putih".
func normalizeFoodName(s string) string {
	s = strings.ToLower(strings.Join(strings.Fields(s), " "))
	return strings.TrimFunc(s, func(r rune) bool { return unicode.IsPunct(r) || unicode.IsSpace(r) })
}

// foodCandidates loads the foods whose name or English name could equal one of the model's names.
func (s *Server) foodCandidates(ctx context.Context, items []photoItem) ([]Food, error) {
	var names []string
	for _, it := range items {
		for _, n := range []string{it.NameID, it.NameEn} {
			if k := normalizeFoodName(n); k != "" {
				names = append(names, k)
			}
		}
	}
	return queryAll[Food](ctx, s.db, `SELECT `+foodColumns+` FROM foods
		WHERE lower(regexp_replace(trim(name), '\s+', ' ', 'g')) = ANY($1)
		   OR lower(regexp_replace(trim(coalesce(name_en, '')), '\s+', ' ', 'g')) = ANY($1)`, names)
}

// pickMatches swaps in database nutrients for items whose Indonesian name equals a food's name, or whose English
// name equals a food's English name, when exactly one food matches. Aliases and partial matches are never used:
// a wrong database food is worse than the model's estimate.
func pickMatches(items []photoItem, foods []Food) []photoItem {
	byName, byNameEn := map[string][]int{}, map[string][]int{}
	for i, f := range foods {
		byName[normalizeFoodName(f.Name)] = append(byName[normalizeFoodName(f.Name)], i)
		if f.NameEn != nil {
			key := normalizeFoodName(*f.NameEn)
			byNameEn[key] = append(byNameEn[key], i)
		}
	}

	out := make([]photoItem, len(items))
	for i, it := range items {
		it.Source = "ai"
		matched := map[string]int{} // food id → index in foods
		if key := normalizeFoodName(it.NameID); key != "" {
			for _, fi := range byName[key] {
				matched[foods[fi].ID] = fi
			}
		}
		if key := normalizeFoodName(it.NameEn); key != "" {
			for _, fi := range byNameEn[key] {
				matched[foods[fi].ID] = fi
			}
		}
		if len(matched) == 1 {
			for _, fi := range matched {
				if f := foods[fi]; f.ServingGrams > 0 {
					per := it.Grams / f.ServingGrams
					id, serving := f.ID, f.ServingGrams
					it.Name, it.Source, it.FoodID, it.ServingGrams = f.Name, "database", &id, &serving
					it.CaloriesKcal, it.ProteinG = round1(f.CaloriesKcal*per), round1(f.ProteinG*per)
					it.CarbsG, it.FatG, it.FiberG = round1(f.CarbsG*per), round1(f.FatG*per), round1(f.FiberG*per)
				}
			}
		}
		out[i] = it
	}
	return out
}
