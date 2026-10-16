-- Supabase exposes the public schema through its REST API (anon / authenticated roles).
-- RLS with no policies blocks that path completely, so data is only reachable through this Go API,
-- which connects as the table owner and is not affected by RLS. On plain Postgres this changes nothing.
-- Every new table in a later migration must also get ENABLE ROW LEVEL SECURITY.
DO $$
DECLARE
    t text;
BEGIN
    FOREACH t IN ARRAY ARRAY[
        'foods', 'packaged_products', 'activities', 'stress_questions', 'stress_score_bands', 'stress_factors',
        'nutrition_targets', 'sleep_recommendations', 'daily_intake_limits', 'activity_recommendations',
        'app_defaults', 'food_label_rules', 'coach_tips', 'coach_quick_questions', 'coach_restricted_topics',
        'reminder_texts', 'insight_templates', 'users', 'meal_logs', 'exercise_logs', 'stress_logs',
        'water_logs', 'sleep_logs', 'step_logs']
    LOOP
        EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', t);
    END LOOP;
END $$;
