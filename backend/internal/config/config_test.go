package config

import (
	"testing"
	"time"
)

func requiredEnv(t *testing.T) {
	t.Setenv("DATABASE_URL", "postgres://x")
	t.Setenv("JWT_SECRET", "0123456789abcdef0123456789abcdef")
}

func TestLoadVisionDefaults(t *testing.T) {
	requiredEnv(t)
	c, err := Load()
	if err != nil {
		t.Fatal(err)
	}
	if c.OllamaVisionModel != "gemma4:31b" || c.OllamaVisionTimeout != 30*time.Second {
		t.Fatalf("vision model %q timeout %s, want gemma4:31b and 30s", c.OllamaVisionModel, c.OllamaVisionTimeout)
	}
}

func TestLoadVisionTimeoutInvalid(t *testing.T) {
	requiredEnv(t)
	t.Setenv("OLLAMA_VISION_TIMEOUT", "abc")
	if _, err := Load(); err == nil || err.Error() != "OLLAMA_VISION_TIMEOUT must be a duration such as 30s" {
		t.Fatalf("err = %v", err)
	}
}
