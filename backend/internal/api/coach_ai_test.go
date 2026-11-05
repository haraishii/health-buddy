package api

import (
	"strings"
	"testing"
	"unicode/utf8"
)

func TestCleanModelText(t *testing.T) {
	in := "## Tips\r\n**Tidur** cukup:\n- tidur 7–8 jam\n* minum `air`\n\n\n\n1. jalan kaki"
	want := "Tips\nTidur cukup:\n• tidur 7–8 jam\n• minum air\n\n1. jalan kaki"
	if got := cleanModelText(in); got != want {
		t.Fatalf("got %q\nwant %q", got, want)
	}
}

func TestTruncateRunesKeepsValidUTF8(t *testing.T) {
	s := strings.Repeat("≈", 2100) // 3 bytes each: a byte cut would split a character
	got := truncateRunes(s, 2000)
	if !utf8.ValidString(got) || utf8.RuneCountInString(got) != 2000 {
		t.Fatalf("got %d runes, valid UTF-8 = %v", utf8.RuneCountInString(got), utf8.ValidString(got))
	}
	if truncateRunes("pendek", 2000) != "pendek" {
		t.Fatal("short text must stay the same")
	}
}

func TestAISystemPrompt(t *testing.T) {
	sleep := 5.5
	d := day(0)
	d.SleepHours = &sleep
	p := testPeriod(d)
	p.user = User{Name: "Budi", Email: "budi@example.com", Language: "id"}
	facts := &coachReply{Points: []coachPoint{{Topic: "sleep", Text: "Tidurmu rata-rata 5.5 jam."}},
		Recommendations: []string{"Matikan layar 30 menit sebelum tidur."}}

	got := aiSystemPrompt(p, facts)
	for _, want := range []string{"Bahasa Indonesia", "slept 5.5 h", "sleep 7-9 h", "Tidurmu rata-rata 5.5 jam.",
		"Matikan layar 30 menit sebelum tidur.", "Never diagnose"} {
		if !strings.Contains(got, want) {
			t.Errorf("prompt is missing %q", want)
		}
	}
	for _, private := range []string{"Budi", "budi@example.com"} {
		if strings.Contains(got, private) {
			t.Errorf("prompt must not contain %q", private)
		}
	}

	p.user.Language = "en"
	if !strings.Contains(aiSystemPrompt(p, &coachReply{}), "Always answer in English") {
		t.Error("English users must get English answers")
	}
}
