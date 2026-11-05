// Package ollama calls a chat model on Ollama: Ollama Cloud (https://ollama.com, needs an API key)
// or a local `ollama serve` (http://localhost:11434, no key).
package ollama

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"strings"
)

type Message struct {
	Role    string `json:"role"` // system, user or assistant
	Content string `json:"content"`
}

type Client struct {
	baseURL string
	apiKey  string
	Model   string
	http    *http.Client
}

// New returns a client for baseURL (without a trailing /api). apiKey may be empty for a local server.
func New(baseURL, apiKey, model string) *Client {
	return &Client{baseURL: strings.TrimRight(baseURL, "/"), apiKey: apiKey, Model: model, http: &http.Client{}}
}

type chatRequest struct {
	Model    string         `json:"model"`
	Messages []Message      `json:"messages"`
	Stream   bool           `json:"stream"`
	Think    any            `json:"think,omitempty"`
	Options  map[string]any `json:"options,omitempty"`
}

type chatResponse struct {
	Message    Message `json:"message"`
	DoneReason string  `json:"done_reason"`
	Error      string  `json:"error"`
}

// Chat sends the conversation and returns the model's answer. The deadline comes from ctx.
func (c *Client) Chat(ctx context.Context, messages []Message) (string, error) {
	in := chatRequest{
		Model:    c.Model,
		Messages: messages,
		Stream:   false,
		// num_predict also counts the model's hidden reasoning, so it is well above the answer length.
		Options: map[string]any{"temperature": 0.4, "num_predict": 800},
	}
	// gpt-oss always reasons; "low" keeps answers fast. Other models get no think field, since some reject it.
	if strings.HasPrefix(c.Model, "gpt-oss") {
		in.Think = "low"
	}
	body, err := json.Marshal(in)
	if err != nil {
		return "", err
	}
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, c.baseURL+"/api/chat", bytes.NewReader(body))
	if err != nil {
		return "", err
	}
	req.Header.Set("Content-Type", "application/json")
	if c.apiKey != "" {
		req.Header.Set("Authorization", "Bearer "+c.apiKey)
	}

	resp, err := c.http.Do(req)
	if err != nil {
		return "", fmt.Errorf("ollama: %w", err)
	}
	defer resp.Body.Close()
	raw, err := io.ReadAll(io.LimitReader(resp.Body, 1<<20))
	if err != nil {
		return "", fmt.Errorf("ollama: read response: %w", err)
	}

	var out chatResponse
	jsonErr := json.Unmarshal(raw, &out)
	if resp.StatusCode != http.StatusOK {
		msg := out.Error
		if jsonErr != nil || msg == "" {
			msg = strings.TrimSpace(string(raw))
			if len(msg) > 200 {
				msg = msg[:200]
			}
		}
		return "", fmt.Errorf("ollama: %s: %s", resp.Status, msg)
	}
	if jsonErr != nil {
		return "", fmt.Errorf("ollama: decode response: %w", jsonErr)
	}
	answer := strings.TrimSpace(out.Message.Content)
	if answer == "" {
		return "", errors.New("ollama: empty answer (done_reason " + out.DoneReason + ")")
	}
	return answer, nil
}
