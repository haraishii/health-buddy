package api

import (
	"reflect"
	"testing"
)

func f(v float64) *float64 { return &v }

func TestEvaluateLabels(t *testing.T) {
	rules := []labelRule{
		{Label: "Healthy", AppliesTo: "all foods", Nutrient: "fat_g", Operator: "<=", Threshold: 10, Basis: "per_serving"},
		{Label: "Healthy", AppliesTo: "solid foods only", Nutrient: "fiber_g", Operator: ">=", Threshold: 3, Basis: "per_serving"},
		{Label: "High fat", AppliesTo: "all foods", Nutrient: "fat_g", Operator: ">", Threshold: 20, Basis: "per_serving"},
		{Label: "High sugar", AppliesTo: "drinks only", Nutrient: "sugar_g", Operator: ">", Threshold: 5, Basis: "per_100g"},
	}

	tests := []struct {
		name string
		in   nutrientValues
		want []string
	}{
		{"healthy solid food", nutrientValues{100, false, map[string]*float64{"fat_g": f(6), "fiber_g": f(6)}}, []string{"Healthy"}},
		{"fiber too low", nutrientValues{100, false, map[string]*float64{"fat_g": f(6), "fiber_g": f(1)}}, []string{}},
		{"high fat", nutrientValues{150, false, map[string]*float64{"fat_g": f(24), "fiber_g": f(3)}}, []string{"High fat"}},
		// Drinks skip the solid-only fiber rule; 30 g sugar in 250 ml = 12 g per 100 ml.
		{"sweet drink", nutrientValues{250, true, map[string]*float64{"fat_g": f(0), "sugar_g": f(30)}}, []string{"Healthy", "High sugar"}},
		{"unknown sugar never labelled", nutrientValues{250, true, map[string]*float64{"fat_g": f(0), "sugar_g": nil}}, []string{"Healthy"}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := evaluateLabels(rules, tt.in); !reflect.DeepEqual(got, tt.want) {
				t.Errorf("got %v, want %v", got, tt.want)
			}
		})
	}
}
