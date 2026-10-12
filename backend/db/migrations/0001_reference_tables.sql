-- Reference data: the 7 packages from the Data Requirements Brief (8 October 2026).
-- Column names follow the brief so the team's spreadsheets can be imported directly.
-- Additions beyond the brief are marked "added:" with the reason.

-- Package 1: Food database. Nutrient values are per serving, as in the brief.
-- The API derives per-gram values from serving_grams when a user edits the portion.
CREATE TABLE foods (
    id             text PRIMARY KEY CHECK (id ~ '^MK[0-9]{3,}$'),
    name           text NOT NULL,
    name_en        text,                            -- added: the app UI is in English
    aliases        text[] NOT NULL DEFAULT '{}',    -- added: search synonyms, e.g. "nasgor"
    category       text NOT NULL CHECK (category IN (
                       'staple', 'animal-based side dish', 'plant-based side dish', 'vegetable', 'fruit',
                       'snack and fried food', 'drink', 'mixed dish', 'snack and breakfast')),
    cooking_method text NOT NULL CHECK (cooking_method IN (
                       'raw', 'boiled', 'steamed', 'fried', 'grilled', 'stir-fried', 'none')),
    serving        text NOT NULL,
    serving_grams  numeric(7, 1) NOT NULL CHECK (serving_grams > 0),
    calories_kcal  numeric(7, 1) NOT NULL CHECK (calories_kcal >= 0),
    protein_g      numeric(6, 1) NOT NULL CHECK (protein_g >= 0),
    carbs_g        numeric(6, 1) NOT NULL CHECK (carbs_g >= 0),
    fat_g          numeric(6, 1) NOT NULL CHECK (fat_g >= 0),
    fiber_g        numeric(6, 1) NOT NULL CHECK (fiber_g >= 0),
    sugar_g        numeric(6, 1) CHECK (sugar_g >= 0),
    sodium_mg      numeric(7, 1) CHECK (sodium_mg >= 0),
    source         text NOT NULL,
    notes          text
);

CREATE INDEX foods_category_idx ON foods (category);

-- Package 2: Packaged products, values copied from the Nutrition Facts label per serving.
CREATE TABLE packaged_products (
    barcode              text PRIMARY KEY CHECK (barcode ~ '^([0-9]{8}|[0-9]{12,14})$'),
    product_group        text NOT NULL CHECK (product_group IN (    -- added: tracks the per-group quota
                             'packaged drink', 'snack', 'instant food', 'milk and yogurt',
                             'bread, cereal, oats', 'biscuit', 'other')),
    brand                text NOT NULL,
    product_name         text NOT NULL,
    variant              text,
    package_size         text NOT NULL,
    serving_size         numeric(7, 1) NOT NULL CHECK (serving_size > 0),
    serving_unit         text NOT NULL CHECK (serving_unit IN ('g', 'ml')),  -- added: brief has the number only
    servings_per_package numeric(5, 1) NOT NULL CHECK (servings_per_package > 0),
    calories_kcal        numeric(7, 1) NOT NULL CHECK (calories_kcal >= 0),
    protein_g            numeric(6, 1) NOT NULL CHECK (protein_g >= 0),
    carbs_g              numeric(6, 1) NOT NULL CHECK (carbs_g >= 0),
    fat_g                numeric(6, 1) NOT NULL CHECK (fat_g >= 0),
    sugar_g              numeric(6, 1) CHECK (sugar_g >= 0),
    fiber_g              numeric(6, 1) CHECK (fiber_g >= 0),
    sodium_mg            numeric(7, 1) CHECK (sodium_mg >= 0),
    photo_front          text NOT NULL,
    photo_label          text NOT NULL,
    notes                text
);

-- Package 3: Activities and MET values.
CREATE TABLE activities (
    id               text PRIMARY KEY CHECK (id ~ '^OR[0-9]{3,}$'),
    activity_name    text NOT NULL,
    activity_name_en text,
    category         text NOT NULL CHECK (category IN (
                         'walking and running', 'cycling', 'ball sports', 'racket sports', 'swimming',
                         'weights and calisthenics', 'aerobics and yoga', 'martial arts', 'daily activities',
                         'outdoor')),
    -- added: which Log Exercise button the row belongs to. Together with intensity it picks one row
    -- for "Run + Hard", replacing the hand-written intensity factor in the app.
    activity_group   text NOT NULL CHECK (activity_group IN (
                         'walk', 'run', 'cycling', 'swim', 'gym', 'yoga', 'sports', 'daily', 'other')),
    met              numeric(4, 1) NOT NULL CHECK (met > 0),
    -- Not filled in by the team: derived from MET as the brief says (<3 light, 3-5.9 moderate, >=6 vigorous).
    intensity        text GENERATED ALWAYS AS (
                         CASE WHEN met < 3 THEN 'light' WHEN met < 6 THEN 'moderate' ELSE 'vigorous' END) STORED,
    source_code      text CHECK (source_code ~ '^[0-9]{5}$'),
    source           text NOT NULL,
    notes            text
);

CREATE INDEX activities_group_idx ON activities (activity_group, met);

-- Package 4A: Stress questionnaire.
CREATE TABLE stress_questions (
    question_id    text PRIMARY KEY CHECK (question_id ~ '^P[0-9]{2}$'),
    text_id        text NOT NULL,
    reverse_scored boolean NOT NULL,
    answer_options text NOT NULL,
    source         text NOT NULL
);

-- Package 4B: Meaning of the scores.
CREATE TABLE stress_score_bands (
    category       text PRIMARY KEY CHECK (category IN ('Low', 'Medium', 'High')),
    score_min      smallint NOT NULL,
    score_max      smallint NOT NULL CHECK (score_max >= score_min),
    -- added: the range on the daily 1-10 slider that maps to this category (open question 3).
    scale_min      smallint NOT NULL CHECK (scale_min BETWEEN 1 AND 10),
    scale_max      smallint NOT NULL CHECK (scale_max BETWEEN 1 AND 10 AND scale_max >= scale_min),
    short_message  text NOT NULL,
    support_advice text CHECK (category = 'High' OR support_advice IS NULL),
    source         text NOT NULL
);

-- added: the "What's on your mind?" chips in Stress Check (not covered by the brief).
CREATE TABLE stress_factors (
    id         text PRIMARY KEY CHECK (id ~ '^SF[0-9]{2}$'),
    name       text NOT NULL,
    name_en    text NOT NULL,
    sort_order smallint NOT NULL
);

-- Package 5: Daily nutrition targets (AKG). Pregnant and breastfeeding rows in AKG are additions
-- on top of the woman's age group, so those rows set values_are_additions.
CREATE TABLE nutrition_targets (
    id                  serial PRIMARY KEY,
    group_name          text NOT NULL,
    age_min             smallint NOT NULL,
    age_max             smallint,                    -- NULL = no upper limit
    sex                 char(1) NOT NULL CHECK (sex IN ('M', 'F')),
    life_stage          text NOT NULL DEFAULT 'general' CHECK (life_stage IN (
                            'general', 'pregnant_t1', 'pregnant_t2', 'pregnant_t3',
                            'breastfeeding_0_6m', 'breastfeeding_7_12m')),
    values_are_additions boolean NOT NULL DEFAULT false,
    reference_weight_kg numeric(5, 1),
    reference_height_cm numeric(5, 1),
    energy_kcal         numeric(6, 1) NOT NULL,
    protein_g           numeric(5, 1) NOT NULL,
    fat_g               numeric(5, 1) NOT NULL,
    carbs_g             numeric(5, 1) NOT NULL,
    fiber_g             numeric(5, 1) NOT NULL,
    water_ml            numeric(6, 1) NOT NULL,
    source              text NOT NULL,
    notes               text,
    CHECK (life_stage = 'general' OR (sex = 'F' AND values_are_additions)),
    UNIQUE (sex, life_stage, age_min)
);

-- added: sleep is split out of nutrition_targets because sleep bodies use different age groups than AKG.
CREATE TABLE sleep_recommendations (
    id              serial PRIMARY KEY,
    age_min         smallint NOT NULL,
    age_max         smallint,
    sleep_hours_min numeric(3, 1) NOT NULL,
    sleep_hours_max numeric(3, 1) NOT NULL CHECK (sleep_hours_max >= sleep_hours_min),
    source          text NOT NULL,
    notes           text
);

CREATE TABLE daily_intake_limits (
    nutrient    text PRIMARY KEY CHECK (nutrient IN ('sugar', 'sodium', 'salt', 'total_fat')),
    daily_limit numeric(7, 1) NOT NULL,
    unit        text NOT NULL,
    source      text NOT NULL,
    notes       text
);

CREATE TABLE activity_recommendations (
    id             serial PRIMARY KEY,
    age_group      text NOT NULL,
    age_min        smallint NOT NULL,
    age_max        smallint,
    recommendation text NOT NULL,
    unit           text NOT NULL,
    source         text NOT NULL
);

-- added: values the brief leaves to the developer (e.g. the daily steps target).
CREATE TABLE app_defaults (
    key   text PRIMARY KEY,
    value numeric NOT NULL,
    notes text NOT NULL
);

-- Package 6: Food label rules. One row per condition; a label is given when all its conditions hold.
-- nutrient/operator/basis are added so the app can evaluate the sentence in "condition".
CREATE TABLE food_label_rules (
    id              serial PRIMARY KEY,
    label_name      text NOT NULL,
    applies_to      text NOT NULL CHECK (applies_to IN ('all foods', 'drinks only', 'solid foods only')),
    condition       text NOT NULL,
    nutrient        text NOT NULL CHECK (nutrient IN (
                        'calories_kcal', 'protein_g', 'carbs_g', 'fat_g', 'fiber_g', 'sugar_g', 'sodium_mg')),
    operator        text NOT NULL CHECK (operator IN ('<', '<=', '>', '>=')),
    threshold_value numeric(7, 1) NOT NULL,
    basis           text NOT NULL CHECK (basis IN ('per_serving', 'per_100g')),
    unit_and_basis  text NOT NULL,
    rule_basis      text NOT NULL,
    approved_by     text,
    approval_date   date,
    CHECK ((approved_by IS NULL) = (approval_date IS NULL))
);

-- Package 7A: Tip library.
CREATE TABLE coach_tips (
    id                text PRIMARY KEY CHECK (id ~ '^TP[0-9]{3,}$'),
    topic             text NOT NULL CHECK (topic IN (
                          'sleep', 'food and nutrition', 'protein', 'drinking water', 'activity', 'stress')),
    trigger_condition text NOT NULL,
    tip_text          text NOT NULL CHECK (char_length(tip_text) <= 140),
    source            text NOT NULL,
    reviewed_by       text
);

-- Package 7B: Quick questions. is_default marks the four chips that already exist in the app.
CREATE TABLE coach_quick_questions (
    id               text PRIMARY KEY CHECK (id ~ '^QQ[0-9]{2,}$'),
    question_text    text NOT NULL,
    question_text_en text,
    topic            text NOT NULL,
    is_default       boolean NOT NULL DEFAULT false,
    sort_order       smallint NOT NULL
);

-- Package 7C: Topics that must not be answered as advice.
CREATE TABLE coach_restricted_topics (
    id                text PRIMARY KEY CHECK (id ~ '^RT[0-9]{2,}$'),
    topic             text NOT NULL,
    example_questions text[] NOT NULL CHECK (cardinality(example_questions) BETWEEN 2 AND 3),
    safe_answer       text NOT NULL,
    support_referral  text NOT NULL,
    reviewed_by       text
);

-- Package 7D: Daily reminder texts.
CREATE TABLE reminder_texts (
    id           text PRIMARY KEY CHECK (id ~ '^RM[0-9]{2,}$'),
    time_of_day  text NOT NULL CHECK (time_of_day IN ('morning', 'afternoon', 'evening')),
    kind         text NOT NULL DEFAULT 'daily_check_in' CHECK (kind IN (  -- added: Profile has 3 switches
                     'daily_check_in', 'bedtime', 'weekly_summary')),
    message_text text NOT NULL CHECK (char_length(message_text) <= 80)
);

-- added (7E): sentence templates for AI Insights. {placeholders} are filled by the app.
CREATE TABLE insight_templates (
    id            text PRIMARY KEY CHECK (id ~ '^IN[0-9]{2,}$'),
    topic         text NOT NULL,
    trigger_key   text NOT NULL,
    template_text text NOT NULL,
    source        text NOT NULL,
    reviewed_by   text
);
