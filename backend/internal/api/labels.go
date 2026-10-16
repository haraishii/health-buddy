package api

import (
	"context"
	"sort"
)

// labelRule is one row of Package 6. A label is given when every rule with that label_name
// that applies to the item (drink or solid food) is satisfied.
type labelRule struct {
	Label     string  `db:"label_name"`
	AppliesTo string  `db:"applies_to"`
	Nutrient  string  `db:"nutrient"`
	Operator  string  `db:"operator"`
	Threshold float64 `db:"threshold_value"`
	Basis     string  `db:"basis"`
}

// nutrientValues holds per-serving values keyed by the nutrient column names used in food_label_rules.
// A nil value means the source does not list that nutrient.
type nutrientValues struct {
	ServingGrams float64
	IsDrink      bool
	Values       map[string]*float64
}

func evaluateLabels(rules []labelRule, n nutrientValues) []string {
	passed := map[string]bool{}
	for _, rule := range rules {
		if rule.AppliesTo == "drinks only" && !n.IsDrink || rule.AppliesTo == "solid foods only" && n.IsDrink {
			continue
		}
		ok := passed[rule.Label]
		if _, seen := passed[rule.Label]; !seen {
			ok = true
		}
		passed[rule.Label] = ok && rule.matches(n)
	}

	labels := []string{}
	for label, ok := range passed {
		if ok {
			labels = append(labels, label)
		}
	}
	sort.Strings(labels)
	return labels
}

func (rule labelRule) matches(n nutrientValues) bool {
	v := n.Values[rule.Nutrient]
	if v == nil {
		return false // unknown value: never claim a label we cannot check
	}
	value := *v
	if rule.Basis == "per_100g" {
		if n.ServingGrams <= 0 {
			return false
		}
		value = value * 100 / n.ServingGrams
	}
	switch rule.Operator {
	case "<":
		return value < rule.Threshold
	case "<=":
		return value <= rule.Threshold
	case ">":
		return value > rule.Threshold
	case ">=":
		return value >= rule.Threshold
	}
	return false
}

// labelRules loads the rules approved by a nutritionist, plus drafts when ALLOW_DRAFT_LABEL_RULES is set.
func (s *Server) labelRules(ctx context.Context) ([]labelRule, error) {
	return queryAll[labelRule](ctx, s.db, `
		SELECT label_name, applies_to, nutrient, operator, threshold_value, basis
		FROM food_label_rules
		WHERE approved_by IS NOT NULL OR $1
		ORDER BY id`, s.cfg.AllowDraftLabelRules)
}
