package api

import (
	"bytes"
	"context"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/iwinardhyas/health-buddy/backend/internal/config"
	"github.com/iwinardhyas/health-buddy/backend/internal/ollama"
)

const fencedRice = "```json\n[{\"name_id\":\"nasi putih\",\"name_en\":\"white rice\",\"grams\":200,\"kcal\":260," +
	"\"protein_g\":5.4,\"carbs_g\":56.4,\"fat_g\":0.6,\"fiber_g\":0.8,\"confidence\":1,\"box_2d\":[286,308,908,786]}]\n```"

func TestParsePhotoAnswerFencedList(t *testing.T) {
	items, _, err := parsePhotoAnswer(fencedRice)
	if err != nil {
		t.Fatal(err)
	}
	if len(items) != 1 {
		t.Fatalf("got %d items, want 1", len(items))
	}
	it := items[0]
	if it.NameID != "nasi putih" || it.Grams != 200 || it.CaloriesKcal != 260 {
		t.Fatalf("item = %+v", it)
	}
	if it.Box == nil || *it.Box != (photoBox{XMin: 308, YMin: 286, XMax: 786, YMax: 908}) {
		t.Fatalf("box = %+v, want x 308-786, y 286-908", it.Box)
	}
}

func TestParsePhotoAnswerObjectWithBoxObject(t *testing.T) {
	items, unrecognized, err := parsePhotoAnswer(`{"items":[{"name_id":"x","grams":50,"kcal":10,"protein_g":0,` +
		`"carbs_g":0,"fat_g":0,"confidence":0.5,"box":{"x_min":-5,"y_min":10,"x_max":1200,"y_max":20}}],` +
		`"unrecognized":["blob"]}`)
	if err != nil {
		t.Fatal(err)
	}
	if len(items) != 1 || items[0].Box == nil || *items[0].Box != (photoBox{XMin: 0, YMin: 10, XMax: 1000, YMax: 20}) {
		t.Fatalf("items = %+v", items)
	}
	if len(unrecognized) != 1 || unrecognized[0] != "blob" {
		t.Fatalf("unrecognized = %v", unrecognized)
	}
}

func TestParsePhotoAnswerDropsBadItems(t *testing.T) {
	bad := `[{"name_id":"zero","grams":0,"kcal":1},{"name_id":"huge","grams":2500,"kcal":1},{"name_id":"","grams":10,"kcal":1}]`
	items, _, err := parsePhotoAnswer(bad)
	if err != nil || len(items) != 0 {
		t.Fatalf("items = %+v, err = %v; want none", items, err)
	}

	var many []string
	for i := 0; i < 25; i++ {
		many = append(many, fmt.Sprintf(`{"name_id":"food %d","grams":10,"kcal":1}`, i))
	}
	items, _, err = parsePhotoAnswer("[" + strings.Join(many, ",") + "]")
	if err != nil || len(items) != 20 {
		t.Fatalf("got %d items (err %v), want 20", len(items), err)
	}
}

func TestParsePhotoAnswerEmpty(t *testing.T) {
	items, _, err := parsePhotoAnswer(`{"items":[],"unrecognized":[]}`)
	if err != nil || len(items) != 0 {
		t.Fatalf("items = %v, err = %v", items, err)
	}
	if _, _, err := parsePhotoAnswer("not json"); err == nil {
		t.Fatal("want an error for an answer that is not JSON")
	}
}

func TestNormalizeFoodName(t *testing.T) {
	if got := normalizeFoodName("  Nasi   Putih. "); got != "nasi putih" {
		t.Fatalf("got %q", got)
	}
}

func TestPickMatches(t *testing.T) {
	en := func(s string) *string { return &s }
	foods := []Food{
		{ID: "MK011", Name: "Nasi putih", NameEn: en("White rice"), ServingGrams: 100, CaloriesKcal: 130, ProteinG: 2.7,
			CarbsG: 28.2, FatG: 0.3, FiberG: 0.4},
		{ID: "MK012", Name: "Nasi merah", ServingGrams: 100, CaloriesKcal: 110},
		{ID: "MK017", Name: "Telur rebus", ServingGrams: 50, CaloriesKcal: 78},
		{ID: "MK018", Name: "Telur dadar", ServingGrams: 60, CaloriesKcal: 110},
		{ID: "MK050", Name: "Sambal", ServingGrams: 15, CaloriesKcal: 20},
		{ID: "MK051", Name: "Sambal", ServingGrams: 20, CaloriesKcal: 30},
	}
	items := []photoItem{
		{NameID: "nasi putih", Name: "nasi putih", Grams: 200, CaloriesKcal: 999},
		{NameID: "nasi", Name: "nasi", Grams: 100},
		{NameID: "telur", Name: "telur", Grams: 50},
		{NameID: "sambal", Name: "sambal", Grams: 20},
		{NameID: "nasi uduk", NameEn: "White Rice", Name: "nasi uduk", Grams: 100},
		{NameID: "telur rebus", NameEn: "white rice", Name: "telur rebus", Grams: 50}, // two different foods
	}
	got := pickMatches(items, foods)

	if got[0].Source != "database" || got[0].FoodID == nil || *got[0].FoodID != "MK011" || got[0].CaloriesKcal != 260 ||
		got[0].Name != "Nasi putih" || got[0].ServingGrams == nil || *got[0].ServingGrams != 100 || got[0].ProteinG != 5.4 {
		t.Errorf("nasi putih = %+v", got[0])
	}
	for i, name := range []string{"nasi", "telur", "sambal (ambiguous)"} {
		if got[i+1].Source != "ai" || got[i+1].FoodID != nil {
			t.Errorf("%s = %+v, want an AI estimate", name, got[i+1])
		}
	}
	if got[4].Source != "database" || *got[4].FoodID != "MK011" {
		t.Errorf("English name match = %+v", got[4])
	}
	if got[5].Source != "ai" {
		t.Errorf("Indonesian and English names pointing at different foods = %+v, want ai", got[5])
	}
}

func TestCheckPhotoImage(t *testing.T) {
	jpeg := base64.StdEncoding.EncodeToString([]byte{0xFF, 0xD8, 0xFF, 0xE0, 1, 2})
	png := base64.StdEncoding.EncodeToString([]byte{0x89, 0x50, 0x4E, 0x47, 1, 2})
	gif := base64.StdEncoding.EncodeToString([]byte("GIF89a"))
	big := base64.StdEncoding.EncodeToString(append([]byte{0xFF, 0xD8, 0xFF}, make([]byte, 4<<20)...))
	for _, c := range []struct {
		name, image string
		ok          bool
	}{{"jpeg", jpeg, true}, {"png", png, true}, {"gif", gif, false}, {"empty", "", false},
		{"not base64", "%%%", false}, {"over 4 MB", big, false}} {
		if err := checkPhotoImage(c.image); (err == nil) != c.ok {
			t.Errorf("%s: err = %v, want ok %v", c.name, err, c.ok)
		}
	}
}

// The app shows these messages as they are, so the handler's status codes and texts are part of the contract.
func TestAnalyzeMealPhotoHandler(t *testing.T) {
	jpeg := base64.StdEncoding.EncodeToString([]byte{0xFF, 0xD8, 0xFF, 0xE0, 1, 2})
	answer := func(content string) http.HandlerFunc {
		return func(w http.ResponseWriter, r *http.Request) {
			json.NewEncoder(w).Encode(map[string]any{"message": map[string]string{"role": "assistant", "content": content}})
		}
	}
	slow := func(w http.ResponseWriter, r *http.Request) {
		select {
		case <-r.Context().Done():
		case <-time.After(200 * time.Millisecond):
		}
	}
	notInPlan := func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusPaymentRequired)
		w.Write([]byte(`{"error":"not included in your free usage"}`))
	}

	for _, c := range []struct {
		name       string
		vision     http.HandlerFunc // nil = no vision model configured
		image      string
		wantStatus int
		wantBody   string
	}{
		{"not configured", nil, jpeg, http.StatusServiceUnavailable, "photo recognition is not configured"},
		{"not an image", answer("{}"), base64.StdEncoding.EncodeToString([]byte("GIF89a")), http.StatusBadRequest,
			"image must be a base64 JPEG or PNG under 4 MB"},
		{"model not in plan", notInPlan, jpeg, http.StatusServiceUnavailable, "AI is unavailable right now. Add the food manually."},
		{"slow model", slow, jpeg, http.StatusGatewayTimeout, "Photo analysis took too long. Try again or add the food manually."},
		{"unreadable answer", answer("sorry"), jpeg, http.StatusBadGateway, "Photo analysis failed. Try again or add the food manually."},
		{"no food", answer(`{"items":[],"unrecognized":["a selfie"]}`), jpeg, http.StatusOK, `"items":[]`},
	} {
		t.Run(c.name, func(t *testing.T) {
			s := &Server{cfg: config.Config{OllamaVisionTimeout: 50 * time.Millisecond}}
			if c.vision != nil {
				s = visionServer(t, 50*time.Millisecond, c.vision)
			}
			body, _ := json.Marshal(map[string]string{"image": c.image})
			rec := httptest.NewRecorder()
			s.analyzeMealPhoto(rec, httptest.NewRequest(http.MethodPost, "/api/v1/me/meals/photo", bytes.NewReader(body)), 1)
			if rec.Code != c.wantStatus || !strings.Contains(rec.Body.String(), c.wantBody) {
				t.Fatalf("got %d %s, want %d containing %q", rec.Code, rec.Body.String(), c.wantStatus, c.wantBody)
			}
		})
	}
}

// The photo handler extends its write deadline through the request logger, so the logger must unwrap.
func TestLogRequestsKeepsWriteDeadline(t *testing.T) {
	errs := make(chan error, 1)
	srv := httptest.NewServer((&Server{}).logRequests(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		errs <- http.NewResponseController(w).SetWriteDeadline(time.Now().Add(time.Minute))
	})))
	defer srv.Close()
	resp, err := http.Get(srv.URL)
	if err != nil {
		t.Fatal(err)
	}
	resp.Body.Close()
	if err := <-errs; err != nil {
		t.Fatalf("SetWriteDeadline through logRequests: %v", err)
	}
}

func visionServer(t *testing.T, timeout time.Duration, h http.HandlerFunc) *Server {
	t.Helper()
	srv := httptest.NewServer(h)
	t.Cleanup(srv.Close)
	return &Server{vision: ollama.New(srv.URL, "k", "gemma4:31b"), cfg: config.Config{OllamaVisionTimeout: timeout}}
}

func TestRecognizeMealErrors(t *testing.T) {
	answer := func(content string) http.HandlerFunc {
		return func(w http.ResponseWriter, r *http.Request) {
			json.NewEncoder(w).Encode(map[string]any{"message": map[string]string{"role": "assistant", "content": content}})
		}
	}
	status := func(code int) http.HandlerFunc {
		return func(w http.ResponseWriter, r *http.Request) {
			w.WriteHeader(code)
			w.Write([]byte(`{"error":"nope"}`))
		}
	}
	slow := func(w http.ResponseWriter, r *http.Request) {
		select {
		case <-r.Context().Done():
		case <-time.After(200 * time.Millisecond):
		}
	}

	for _, c := range []struct {
		name string
		h    http.HandlerFunc
		want error
	}{
		{"402 not in plan", status(http.StatusPaymentRequired), errPhotoUnavailable},
		{"429 rate limited", status(http.StatusTooManyRequests), errPhotoUnavailable},
		{"slow model", slow, errPhotoTimeout},
		{"not json", answer("sorry"), errPhotoFailed},
		{"server error", status(http.StatusInternalServerError), errPhotoFailed},
	} {
		t.Run(c.name, func(t *testing.T) {
			s := visionServer(t, 50*time.Millisecond, c.h)
			if _, err := s.recognizeMeal(context.Background(), "aGk="); !errors.Is(err, c.want) {
				t.Fatalf("err = %v, want %v", err, c.want)
			}
		})
	}

	t.Run("success", func(t *testing.T) {
		var body map[string]any
		s := visionServer(t, time.Second, func(w http.ResponseWriter, r *http.Request) {
			json.NewDecoder(r.Body).Decode(&body)
			answer(fencedRice)(w, r)
		})
		res, err := s.recognizeMeal(context.Background(), "aGk=")
		if err != nil {
			t.Fatal(err)
		}
		if res.Model != "gemma4:31b" || len(res.Items) != 1 {
			t.Fatalf("result = %+v", res)
		}
		msg := body["messages"].([]any)[0].(map[string]any)
		if msg["content"] != photoPrompt || len(msg["images"].([]any)) != 1 || body["think"] != false {
			t.Fatalf("request = %v", body)
		}
	})
}
