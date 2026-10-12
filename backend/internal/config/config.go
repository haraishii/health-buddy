// Package config reads settings from environment variables.
package config

import (
	"errors"
	"os"
	"strconv"
	"time"
)

type Config struct {
	Port        string
	DatabaseURL string
	JWTSecret   string
	TokenTTL    time.Duration
	CORSOrigin  string

	// AllowDraftLabelRules makes the API use food label rules that a nutritionist has not approved yet.
	// Only for local testing with the dummy rules.
	AllowDraftLabelRules bool
}

func Load() (Config, error) {
	c := Config{
		Port:        getenv("PORT", "8080"),
		DatabaseURL: os.Getenv("DATABASE_URL"),
		JWTSecret:   os.Getenv("JWT_SECRET"),
		CORSOrigin:  getenv("CORS_ORIGIN", "*"),
	}
	if c.DatabaseURL == "" {
		return c, errors.New("DATABASE_URL is required")
	}
	if len(c.JWTSecret) < 32 {
		return c, errors.New("JWT_SECRET must be at least 32 characters")
	}

	ttl, err := time.ParseDuration(getenv("TOKEN_TTL", "72h"))
	if err != nil {
		return c, errors.New("TOKEN_TTL must be a duration such as 72h")
	}
	c.TokenTTL = ttl

	c.AllowDraftLabelRules, _ = strconv.ParseBool(os.Getenv("ALLOW_DRAFT_LABEL_RULES"))
	return c, nil
}

func getenv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
