package api

import (
	"testing"
	"time"
)

func testPeriod(days ...DayStats) *period {
	minH, maxH := 7.0, 9.0
	p := &period{
		targets:  &Targets{EnergyKcal: 2000, ProteinG: 60, FiberG: 30, WaterMl: 2000, StepsTarget: 8000, SleepHoursMin: &minH, SleepHoursMax: &maxH},
		days:     days,
		settings: map[string]float64{},
	}
	p.now = averages(untilToday(days))
	return p
}

func day(offset int) DayStats {
	return DayStats{Date: time.Now().AddDate(0, 0, offset).Format(dateLayout)}
}

func TestScoreDay(t *testing.T) {
	d := day(0)
	d.CaloriesIn, d.ProteinG, d.FiberG = 2000, 60, 30 // nutrition 100
	sleep, stress, steps := 8.0, 1.0, 8000
	d.SleepHours, d.StressAvg, d.Steps = &sleep, &stress, &steps // sleep 100, stress 100
	d.ExerciseMinutes = 30                                       // exercise 100
	if got := testPeriod(d).scoreDay(d); got.Score == nil || *got.Score != 100 {
		t.Fatalf("perfect day: got %v, want 100", got.Score)
	}

	empty := day(0)
	if got := testPeriod(empty).scoreDay(empty); got.Score != nil {
		t.Fatalf("day without data must have no score, got %v", *got.Score)
	}

	// Only stress logged: the score is the stress part alone (10 = very stressed -> 0).
	s := day(0)
	high := 10.0
	s.StressAvg = &high
	if got := testPeriod(s).scoreDay(s); got.Score == nil || *got.Score != 0 {
		t.Fatalf("stress-only day: got %v, want 0", got.Score)
	}
}

func TestTriggersNeedData(t *testing.T) {
	p := testPeriod(day(-2), day(-1), day(0))
	for key, on := range p.triggers() {
		if on {
			t.Errorf("trigger %q fired for a user without any data", key)
		}
	}

	d := day(0)
	d.WaterMl = 2500
	p = testPeriod(day(-2), day(-1), d)
	on := p.triggers()
	if !on["water_target_reached"] || !on["no_exercise_3_days"] {
		t.Errorf("expected water_target_reached and no_exercise_3_days, got %v", on)
	}
}

func TestLastSkipsFutureDays(t *testing.T) {
	p := testPeriod(day(-1), day(0), day(1), day(2))
	if got, want := p.last().Date, day(0).Date; got != want {
		t.Errorf("last() = %s, want today %s", got, want)
	}
}
