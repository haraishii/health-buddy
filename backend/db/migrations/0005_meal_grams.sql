-- Weight of a logged meal item in grams, set by Scan Meal photos (POST /me/meals/batch). Older rows stay NULL.
ALTER TABLE meal_logs ADD COLUMN grams numeric(7, 1) CHECK (grams > 0);
