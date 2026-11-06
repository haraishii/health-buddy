package api

import (
	"strings"
	"testing"
)

func TestValidateBatch(t *testing.T) {
	id := func(s string) *string { return &s }
	rice := batchItem{FoodID: id("MK011"), Grams: 200}
	custom := func(name string, kcal float64) batchItem {
		return batchItem{Custom: &customFood{Name: name, CaloriesKcal: kcal}, Grams: 30}
	}
	many := make([]batchItem, 31)
	for i := range many {
		many[i] = rice
	}

	const (
		badCount  = "items must have 1 to 30 entries"
		badMeal   = "meal_time must be breakfast, lunch, dinner or snack"
		badSource = "each item needs exactly one of food_id or custom"
		badGrams  = "grams must be above 0 and at most 2000"
		badCustom = "custom needs a name and non-negative nutrients"
		tooLarge  = "custom nutrients are too large"
	)
	for _, c := range []struct {
		name string
		in   batchInput
		want string // "" = valid
	}{
		{"ok", batchInput{MealTime: "lunch", Items: []batchItem{rice, custom("sambal ijo", 30)}}, ""},
		{"empty", batchInput{MealTime: "lunch"}, badCount},
		{"31 items", batchInput{MealTime: "lunch", Items: many}, badCount},
		{"bad meal time", batchInput{MealTime: "brunch", Items: []batchItem{rice}}, badMeal},
		{"both sources", batchInput{MealTime: "lunch", Items: []batchItem{{FoodID: id("MK011"), Custom: &customFood{Name: "x"}, Grams: 10}}}, badSource},
		{"no source", batchInput{MealTime: "lunch", Items: []batchItem{{Grams: 10}}}, badSource},
		{"zero grams", batchInput{MealTime: "dinner", Items: []batchItem{{FoodID: id("MK011")}}}, badGrams},
		{"2001 grams", batchInput{MealTime: "dinner", Items: []batchItem{{FoodID: id("MK011"), Grams: 2001}}}, badGrams},
		{"custom without name", batchInput{MealTime: "snack", Items: []batchItem{custom("  ", 10)}}, badCustom},
		{"custom negative kcal", batchInput{MealTime: "snack", Items: []batchItem{custom("tahu", -1)}}, badCustom},
		{"custom absurd kcal", batchInput{MealTime: "snack", Items: []batchItem{custom("tahu", 200000)}}, tooLarge},
	} {
		t.Run(c.name, func(t *testing.T) {
			err := validateBatch(c.in)
			switch {
			case c.want == "" && err != nil:
				t.Fatalf("want valid, got %v", err)
			case c.want != "" && (err == nil || err.Error() != c.want):
				t.Fatalf("err = %v, want %q", err, c.want)
			}
		})
	}
}

// The batch insert and the meal list read the same columns; grams must be in both.
func TestMealSelectHasGrams(t *testing.T) {
	if !strings.Contains(mealSelect, "m.grams") {
		t.Fatal("mealSelect does not read m.grams, so saved weights never reach the app")
	}
}
