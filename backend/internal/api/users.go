package api

import (
	"errors"
	"net/http"
	"net/mail"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"

	"github.com/iwinardhyas/health-buddy/backend/internal/auth"
)

type User struct {
	ID          int64     `json:"id"`
	Email       string    `json:"email"`
	Name        string    `json:"name"`
	Status      string    `json:"status"`
	BirthDate   *string   `json:"birth_date"`
	Age         *int      `json:"age"`
	Sex         *string   `json:"sex"`
	HeightCm    *float64  `json:"height_cm"`
	WeightKg    *float64  `json:"weight_kg"`
	LifeStage   string    `json:"life_stage"`
	StepsTarget *int      `json:"steps_target"`
	CreatedAt   time.Time `json:"created_at"`

	// Profile > Settings.
	ReminderDaily   bool   `json:"reminder_daily"`
	ReminderBedtime bool   `json:"reminder_bedtime"`
	BedtimeTime     string `json:"bedtime_time"` // HH:MM
	WeeklySummary   bool   `json:"weekly_summary"`
	Language        string `json:"language"`
}

const userColumns = `id, email, name, status, birth_date, sex, height_cm, weight_kg, life_stage, steps_target, created_at,
	reminder_daily, reminder_bedtime, to_char(bedtime_time, 'HH24:MI'), weekly_summary, language`

func scanUser(row pgx.Row) (User, error) {
	var u User
	var birth *time.Time
	err := row.Scan(&u.ID, &u.Email, &u.Name, &u.Status, &birth, &u.Sex, &u.HeightCm, &u.WeightKg, &u.LifeStage,
		&u.StepsTarget, &u.CreatedAt, &u.ReminderDaily, &u.ReminderBedtime, &u.BedtimeTime, &u.WeeklySummary, &u.Language)
	if birth != nil {
		s := birth.Format(dateLayout)
		u.BirthDate = &s
		age := ageOn(*birth, time.Now())
		u.Age = &age
	}
	return u, err
}

func ageOn(birth, on time.Time) int {
	age := on.Year() - birth.Year()
	if on.Month() < birth.Month() || (on.Month() == birth.Month() && on.Day() < birth.Day()) {
		age--
	}
	return age
}

type authResponse struct {
	Token     string    `json:"token"`
	ExpiresAt time.Time `json:"expires_at"`
	User      User      `json:"user"`
}

func (s *Server) respondWithToken(w http.ResponseWriter, status int, u User) {
	token, exp, err := s.tokens.Issue(u.ID)
	if err != nil {
		serverError(w, err)
		return
	}
	writeJSON(w, status, authResponse{Token: token, ExpiresAt: exp, User: u})
}

func (s *Server) signUp(w http.ResponseWriter, r *http.Request) {
	var in struct {
		Email    string `json:"email"`
		Password string `json:"password"`
		Name     string `json:"name"`
	}
	if !decode(w, r, &in) {
		return
	}
	in.Email = strings.ToLower(strings.TrimSpace(in.Email))
	in.Name = strings.TrimSpace(in.Name)
	if addr, err := mail.ParseAddress(in.Email); err != nil || addr.Address != in.Email {
		writeError(w, http.StatusBadRequest, "email is not valid")
		return
	}
	if len(in.Password) < 8 || len(in.Password) > 72 {
		writeError(w, http.StatusBadRequest, "password must be 8 to 72 characters")
		return
	}
	if in.Name == "" {
		writeError(w, http.StatusBadRequest, "name is required")
		return
	}

	hash, err := auth.HashPassword(in.Password)
	if err != nil {
		serverError(w, err)
		return
	}
	u, err := scanUser(s.db.QueryRow(r.Context(),
		`INSERT INTO users (email, password_hash, name) VALUES ($1, $2, $3) RETURNING `+userColumns,
		in.Email, hash, in.Name))
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) && pgErr.Code == "23505" {
		writeError(w, http.StatusConflict, "email is already registered")
		return
	}
	if err != nil {
		serverError(w, err)
		return
	}
	s.respondWithToken(w, http.StatusCreated, u)
}

func (s *Server) signIn(w http.ResponseWriter, r *http.Request) {
	var in struct {
		Email    string `json:"email"`
		Password string `json:"password"`
	}
	if !decode(w, r, &in) {
		return
	}

	var hash string
	var id int64
	err := s.db.QueryRow(r.Context(), `SELECT id, password_hash FROM users WHERE lower(email) = lower($1)`,
		strings.TrimSpace(in.Email)).Scan(&id, &hash)
	if err != nil && !isNoRows(err) {
		serverError(w, err)
		return
	}
	// Same message for unknown email and wrong password, so emails cannot be probed.
	if isNoRows(err) || !auth.CheckPassword(hash, in.Password) {
		writeError(w, http.StatusUnauthorized, "email or password is incorrect")
		return
	}

	u, err := s.loadUser(r, id)
	if err != nil {
		serverError(w, err)
		return
	}
	s.respondWithToken(w, http.StatusOK, u)
}

func (s *Server) loadUser(r *http.Request, id int64) (User, error) {
	return scanUser(s.db.QueryRow(r.Context(), `SELECT `+userColumns+` FROM users WHERE id = $1`, id))
}

func (s *Server) getMe(w http.ResponseWriter, r *http.Request, userID int64) {
	u, err := s.loadUser(r, userID)
	if isNoRows(err) {
		writeError(w, http.StatusUnauthorized, "user no longer exists")
		return
	}
	if err != nil {
		serverError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, u)
}

// updateMe changes only the fields that are present in the body.
func (s *Server) updateMe(w http.ResponseWriter, r *http.Request, userID int64) {
	var in struct {
		Name        *string  `json:"name"`
		Status      *string  `json:"status"`
		BirthDate   *string  `json:"birth_date"`
		Sex         *string  `json:"sex"`
		HeightCm    *float64 `json:"height_cm"`
		WeightKg    *float64 `json:"weight_kg"`
		LifeStage   *string  `json:"life_stage"`
		StepsTarget *int     `json:"steps_target"`

		ReminderDaily   *bool   `json:"reminder_daily"`
		ReminderBedtime *bool   `json:"reminder_bedtime"`
		BedtimeTime     *string `json:"bedtime_time"`
		WeeklySummary   *bool   `json:"weekly_summary"`
		Language        *string `json:"language"`

		// steps_target cannot be cleared with null in a COALESCE update, so this flag does it.
		ClearStepsTarget bool `json:"clear_steps_target"`
	}
	if !decode(w, r, &in) {
		return
	}
	if in.BedtimeTime != nil {
		if _, err := time.Parse("15:04", *in.BedtimeTime); err != nil {
			writeError(w, http.StatusBadRequest, "bedtime_time must be HH:MM")
			return
		}
	}

	var birth *time.Time
	if in.BirthDate != nil {
		t, err := time.Parse(dateLayout, *in.BirthDate)
		if err != nil || t.After(time.Now()) {
			writeError(w, http.StatusBadRequest, "birth_date must be a past date in YYYY-MM-DD")
			return
		}
		birth = &t
	}
	if in.Name != nil && strings.TrimSpace(*in.Name) == "" {
		writeError(w, http.StatusBadRequest, "name cannot be empty")
		return
	}

	u, err := scanUser(s.db.QueryRow(r.Context(), `
		UPDATE users SET
			name = COALESCE($2, name),
			status = COALESCE($3, status),
			birth_date = COALESCE($4, birth_date),
			sex = COALESCE($5, sex),
			height_cm = COALESCE($6, height_cm),
			weight_kg = COALESCE($7, weight_kg),
			life_stage = COALESCE($8, life_stage),
			steps_target = CASE WHEN $10::bool THEN NULL ELSE COALESCE($9, steps_target) END,
			reminder_daily = COALESCE($11, reminder_daily),
			reminder_bedtime = COALESCE($12, reminder_bedtime),
			bedtime_time = COALESCE($13::text::time, bedtime_time),
			weekly_summary = COALESCE($14, weekly_summary),
			language = COALESCE($15, language),
			updated_at = now()
		WHERE id = $1
		RETURNING `+userColumns,
		userID, in.Name, in.Status, birth, in.Sex, in.HeightCm, in.WeightKg, in.LifeStage, in.StepsTarget,
		in.ClearStepsTarget, in.ReminderDaily, in.ReminderBedtime, in.BedtimeTime, in.WeeklySummary, in.Language))
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) && pgErr.Code == "23514" {
		writeError(w, http.StatusBadRequest,
			"invalid value: sex is M or F, life_stage needs sex F, height 50-250 cm, weight 20-300 kg, language en or id")
		return
	}
	if err != nil {
		serverError(w, err)
		return
	}
	writeJSON(w, http.StatusOK, u)
}
