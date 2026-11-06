package ollama

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"
)

func TestChatSendsKeyModelAndThink(t *testing.T) {
	var got chatRequest
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/api/chat" || r.Method != http.MethodPost {
			t.Errorf("got %s %s, want POST /api/chat", r.Method, r.URL.Path)
		}
		if auth := r.Header.Get("Authorization"); auth != "Bearer secret-key" {
			t.Errorf("Authorization = %q", auth)
		}
		if err := json.NewDecoder(r.Body).Decode(&got); err != nil {
			t.Error(err)
		}
		w.Write([]byte(`{"model":"gpt-oss:120b","message":{"role":"assistant","content":"  Tidur 7 jam.  ","thinking":"x"},"done":true}`))
	}))
	defer srv.Close()

	answer, err := New(srv.URL+"/", "secret-key", "gpt-oss:120b").
		Chat(context.Background(), []Message{{Role: "user", Content: "hi"}})
	if err != nil {
		t.Fatal(err)
	}
	if answer != "Tidur 7 jam." {
		t.Fatalf("answer = %q", answer)
	}
	if got.Model != "gpt-oss:120b" || got.Stream || got.Think != "low" || len(got.Messages) != 1 {
		t.Fatalf("request = %+v", got)
	}
}

func TestChatLocalServerHasNoKeyAndOtherModelsNoThink(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if auth := r.Header.Get("Authorization"); auth != "" {
			t.Errorf("Authorization = %q, want none", auth)
		}
		var in map[string]any
		json.NewDecoder(r.Body).Decode(&in)
		if _, ok := in["think"]; ok {
			t.Errorf("think sent for a non gpt-oss model")
		}
		w.Write([]byte(`{"message":{"role":"assistant","content":"ok"}}`))
	}))
	defer srv.Close()

	if _, err := New(srv.URL, "", "llama3.2:3b").Chat(context.Background(), nil); err != nil {
		t.Fatal(err)
	}
}

func TestChatErrors(t *testing.T) {
	cases := []struct {
		name, body, want string
		status           int
	}{
		{"bad key", `{"error":"unauthorized"}`, "401 Unauthorized: unauthorized", http.StatusUnauthorized},
		{"plain text error", `upstream down`, "502 Bad Gateway: upstream down", http.StatusBadGateway},
		{"empty answer", `{"message":{"role":"assistant","content":""},"done_reason":"length"}`, "empty answer (done_reason length)", http.StatusOK},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				w.WriteHeader(c.status)
				w.Write([]byte(c.body))
			}))
			defer srv.Close()
			_, err := New(srv.URL, "k", "gpt-oss:120b").Chat(context.Background(), nil)
			if err == nil || !strings.Contains(err.Error(), c.want) {
				t.Fatalf("err = %v, want it to contain %q", err, c.want)
			}
		})
	}
}

func TestChatWithSendsImagesAndThinkFalse(t *testing.T) {
	var body map[string]any
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if err := json.NewDecoder(r.Body).Decode(&body); err != nil {
			t.Error(err)
		}
		w.Write([]byte(`{"message":{"role":"assistant","content":"ok"}}`))
	}))
	defer srv.Close()

	_, err := New(srv.URL, "k", "gemma4:31b").ChatWith(context.Background(), Request{
		Messages:    []Message{{Role: "user", Content: "what food?", Images: []string{"aGk="}}},
		Think:       false,
		Temperature: 0.2,
		NumPredict:  2048,
	})
	if err != nil {
		t.Fatal(err)
	}
	if think, ok := body["think"]; !ok || think != false {
		t.Errorf("think = %v (present %v), want false", think, ok)
	}
	opts, _ := body["options"].(map[string]any)
	if opts["temperature"] != 0.2 || opts["num_predict"] != float64(2048) {
		t.Errorf("options = %v", opts)
	}
	msgs, _ := body["messages"].([]any)
	first, _ := msgs[0].(map[string]any)
	if imgs, _ := first["images"].([]any); len(imgs) != 1 || imgs[0] != "aGk=" {
		t.Errorf("images = %v", first["images"])
	}
}

func TestChatWithStatusError(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusPaymentRequired)
		w.Write([]byte(`{"error":"not included in your free usage"}`))
	}))
	defer srv.Close()

	_, err := New(srv.URL, "k", "gemma4:31b").ChatWith(context.Background(), Request{})
	var se *StatusError
	if !errors.As(err, &se) || se.StatusCode != http.StatusPaymentRequired {
		t.Fatalf("err = %v, want a *StatusError with 402", err)
	}
	if !strings.Contains(err.Error(), "402 Payment Required: not included in your free usage") {
		t.Fatalf("err = %q", err)
	}
}

func TestChatStopsAtDeadline(t *testing.T) {
	srv := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		select {
		case <-r.Context().Done():
		case <-time.After(2 * time.Second):
		}
	}))
	defer srv.Close()

	ctx, cancel := context.WithTimeout(context.Background(), 50*time.Millisecond)
	defer cancel()
	start := time.Now()
	if _, err := New(srv.URL, "k", "gpt-oss:120b").Chat(ctx, nil); err == nil {
		t.Fatal("want a timeout error")
	}
	if time.Since(start) > time.Second {
		t.Fatal("Chat did not stop at the context deadline")
	}
}
