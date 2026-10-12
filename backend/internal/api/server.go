// Package api holds the HTTP handlers for the Health Buddy app.
package api

import (
	"encoding/json"
	"errors"
	"io"
	"log"
	"net/http"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/iwinardhyas/health-buddy/backend/internal/auth"
	"github.com/iwinardhyas/health-buddy/backend/internal/config"
)

type Server struct {
	db     *pgxpool.Pool
	tokens *auth.Tokens
	cfg    config.Config
}

func NewServer(db *pgxpool.Pool, cfg config.Config) *Server {
	return &Server{db: db, tokens: auth.NewTokens(cfg.JWTSecret, cfg.TokenTTL), cfg: cfg}
}

func (s *Server) Routes() http.Handler {
	mux := http.NewServeMux()
	user := s.requireUser

	mux.HandleFunc("GET /healthz", s.health)

	mux.HandleFunc("POST /api/v1/auth/signup", s.signUp)
	mux.HandleFunc("POST /api/v1/auth/signin", s.signIn)

	// Reference data (Packages 1-7). Public: it holds no personal data.
	mux.HandleFunc("GET /api/v1/foods", s.searchFoods)
	mux.HandleFunc("GET /api/v1/foods/{id}", s.getFood)
	mux.HandleFunc("GET /api/v1/products/{barcode}", s.getProduct)
	mux.HandleFunc("GET /api/v1/activities", s.listActivities)
	mux.HandleFunc("GET /api/v1/stress/questionnaire", s.stressQuestionnaire)
	mux.HandleFunc("GET /api/v1/coach/content", s.coachContent)

	mux.Handle("GET /api/v1/me", user(s.getMe))
	mux.Handle("PATCH /api/v1/me", user(s.updateMe))
	mux.Handle("GET /api/v1/me/targets", user(s.getTargets))
	mux.Handle("GET /api/v1/me/summary", user(s.getSummary))
	mux.Handle("GET /api/v1/me/analytics", user(s.getAnalytics))

	mux.Handle("GET /api/v1/me/meals", user(s.listMeals))
	mux.Handle("POST /api/v1/me/meals", user(s.createMeal))
	mux.Handle("DELETE /api/v1/me/meals/{id}", user(s.deleteMeal))
	mux.Handle("GET /api/v1/me/exercises", user(s.listExercises))
	mux.Handle("POST /api/v1/me/exercises", user(s.createExercise))
	mux.Handle("DELETE /api/v1/me/exercises/{id}", user(s.deleteExercise))
	mux.Handle("GET /api/v1/me/stress", user(s.listStress))
	mux.Handle("POST /api/v1/me/stress", user(s.createStress))
	mux.Handle("POST /api/v1/me/water", user(s.addWater))
	mux.Handle("PUT /api/v1/me/sleep/{date}", user(s.putSleep))
	mux.Handle("PUT /api/v1/me/steps/{date}", user(s.putSteps))

	return s.recoverer(s.logRequests(s.cors(mux)))
}

func (s *Server) health(w http.ResponseWriter, r *http.Request) {
	if err := s.db.Ping(r.Context()); err != nil {
		writeError(w, http.StatusServiceUnavailable, "database unavailable")
		return
	}
	writeJSON(w, http.StatusOK, map[string]string{"status": "ok"})
}

// --- middleware ---

// requireUser rejects requests without a valid bearer token and passes the user id to the handler.
func (s *Server) requireUser(h func(http.ResponseWriter, *http.Request, int64)) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		token, ok := strings.CutPrefix(r.Header.Get("Authorization"), "Bearer ")
		if !ok {
			writeError(w, http.StatusUnauthorized, "missing bearer token")
			return
		}
		userID, err := s.tokens.Verify(token)
		if err != nil {
			writeError(w, http.StatusUnauthorized, "invalid or expired token")
			return
		}
		h(w, r, userID)
	})
}

func (s *Server) cors(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", s.cfg.CORSOrigin)
		w.Header().Set("Access-Control-Allow-Headers", "Authorization, Content-Type")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
		if r.Method == http.MethodOptions {
			w.WriteHeader(http.StatusNoContent)
			return
		}
		next.ServeHTTP(w, r)
	})
}

type statusRecorder struct {
	http.ResponseWriter
	status int
}

func (r *statusRecorder) WriteHeader(code int) {
	r.status = code
	r.ResponseWriter.WriteHeader(code)
}

func (s *Server) logRequests(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		rec := &statusRecorder{ResponseWriter: w, status: http.StatusOK}
		next.ServeHTTP(rec, r)
		log.Printf("%s %s %d %s", r.Method, r.URL.Path, rec.status, time.Since(start).Round(time.Millisecond))
	})
}

func (s *Server) recoverer(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if v := recover(); v != nil {
				log.Printf("panic: %v", v)
				writeError(w, http.StatusInternalServerError, "internal error")
			}
		}()
		next.ServeHTTP(w, r)
	})
}

// --- helpers ---

func writeJSON(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(v); err != nil {
		log.Printf("encode response: %v", err)
	}
}

func writeError(w http.ResponseWriter, status int, msg string) {
	writeJSON(w, status, map[string]string{"error": msg})
}

// serverError logs the real error and hides it from the client.
func serverError(w http.ResponseWriter, err error) {
	log.Printf("error: %v", err)
	writeError(w, http.StatusInternalServerError, "internal error")
}

// decode reads a JSON body of at most 1 MB and rejects unknown fields.
func decode(w http.ResponseWriter, r *http.Request, dst any) bool {
	dec := json.NewDecoder(http.MaxBytesReader(w, r.Body, 1<<20))
	dec.DisallowUnknownFields()
	if err := dec.Decode(dst); err != nil {
		if errors.Is(err, io.EOF) {
			writeError(w, http.StatusBadRequest, "request body is empty")
		} else {
			writeError(w, http.StatusBadRequest, "invalid JSON: "+err.Error())
		}
		return false
	}
	return true
}

const dateLayout = "2006-01-02"

// parseDate reads YYYY-MM-DD; an empty string means today on the server.
// Clients should always send their own local date so "today" matches the phone.
func parseDate(v string) (time.Time, error) {
	if v == "" {
		y, m, d := time.Now().Date()
		return time.Date(y, m, d, 0, 0, 0, 0, time.UTC), nil
	}
	return time.Parse(dateLayout, v)
}

// dateRange reads ?from=&to= (inclusive). Defaults to the 7 days ending today; at most 92 days.
func dateRange(w http.ResponseWriter, r *http.Request) (from, to time.Time, ok bool) {
	to, err := parseDate(r.URL.Query().Get("to"))
	if err != nil {
		writeError(w, http.StatusBadRequest, "to must be YYYY-MM-DD")
		return from, to, false
	}
	from = to.AddDate(0, 0, -6)
	if v := r.URL.Query().Get("from"); v != "" {
		if from, err = time.Parse(dateLayout, v); err != nil {
			writeError(w, http.StatusBadRequest, "from must be YYYY-MM-DD")
			return from, to, false
		}
	}
	if from.After(to) || to.Sub(from) > 92*24*time.Hour {
		writeError(w, http.StatusBadRequest, "from must be before to, within 92 days")
		return from, to, false
	}
	return from, to, true
}

func isNoRows(err error) bool { return errors.Is(err, pgx.ErrNoRows) }
