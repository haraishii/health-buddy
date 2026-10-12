-- User accounts and the data users create in the app ("Data the team does not need to collect").

CREATE TABLE users (
    id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email         text NOT NULL,
    password_hash text NOT NULL,
    name          text NOT NULL,
    status        text NOT NULL DEFAULT 'Student',
    birth_date    date,
    sex           char(1) CHECK (sex IN ('M', 'F')),
    height_cm     numeric(5, 1) CHECK (height_cm BETWEEN 50 AND 250),
    weight_kg     numeric(5, 1) CHECK (weight_kg BETWEEN 20 AND 300),
    life_stage    text NOT NULL DEFAULT 'general' CHECK (life_stage IN (
                      'general', 'pregnant_t1', 'pregnant_t2', 'pregnant_t3',
                      'breastfeeding_0_6m', 'breastfeeding_7_12m')),
    steps_target  integer CHECK (steps_target > 0),  -- NULL = app_defaults.steps_target
    created_at    timestamptz NOT NULL DEFAULT now(),
    updated_at    timestamptz NOT NULL DEFAULT now(),
    CHECK (life_stage = 'general' OR sex = 'F')
);

CREATE UNIQUE INDEX users_email_key ON users (lower(email));

-- Nutrients are stored already multiplied by servings, so later corrections to the food tables
-- (v2 files) do not rewrite a user's history.
CREATE TABLE meal_logs (
    id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id       bigint NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    logged_on     date NOT NULL,
    meal_time     text NOT NULL CHECK (meal_time IN ('breakfast', 'lunch', 'dinner', 'snack')),
    food_id       text REFERENCES foods (id),
    barcode       text REFERENCES packaged_products (barcode),
    custom_name   text,                       -- e.g. a Scan Meal photo result not in Package 1
    servings      numeric(5, 2) NOT NULL CHECK (servings > 0),
    calories_kcal numeric(7, 1) NOT NULL,
    protein_g     numeric(6, 1) NOT NULL,
    carbs_g       numeric(6, 1) NOT NULL,
    fat_g         numeric(6, 1) NOT NULL,
    fiber_g       numeric(6, 1),
    sugar_g       numeric(6, 1),
    sodium_mg     numeric(7, 1),
    created_at    timestamptz NOT NULL DEFAULT now(),
    CHECK (num_nonnulls(food_id, barcode, custom_name) = 1)
);

CREATE INDEX meal_logs_user_day_idx ON meal_logs (user_id, logged_on);

-- Calories burned = met x weight_kg x minutes / 60; met and weight are snapshots at logging time.
CREATE TABLE exercise_logs (
    id            bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id       bigint NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    logged_on     date NOT NULL,
    activity_id   text NOT NULL REFERENCES activities (id),
    minutes       smallint NOT NULL CHECK (minutes BETWEEN 1 AND 600),
    met           numeric(4, 1) NOT NULL,
    weight_kg     numeric(5, 1) NOT NULL,
    calories_kcal numeric(7, 1) NOT NULL,
    note          text,
    created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX exercise_logs_user_day_idx ON exercise_logs (user_id, logged_on);

CREATE TABLE stress_logs (
    id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id    bigint NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    logged_on  date NOT NULL,
    level      smallint NOT NULL CHECK (level BETWEEN 1 AND 10),
    factor_ids text[] NOT NULL DEFAULT '{}',
    note       text,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX stress_logs_user_day_idx ON stress_logs (user_id, logged_on);

-- One row per tap on "+ 250 ml".
CREATE TABLE water_logs (
    id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id    bigint NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    logged_on  date NOT NULL,
    amount_ml  integer NOT NULL CHECK (amount_ml BETWEEN 1 AND 5000),
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX water_logs_user_day_idx ON water_logs (user_id, logged_on);

-- sleep_date is the morning the night ended ("Sleep last night" on that day's Home).
CREATE TABLE sleep_logs (
    user_id    bigint NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    sleep_date date NOT NULL,
    hours      numeric(4, 2) NOT NULL CHECK (hours BETWEEN 0 AND 24),
    updated_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, sleep_date)
);

-- Daily total synced from Health Connect / HealthKit; the latest sync replaces the value.
CREATE TABLE step_logs (
    user_id    bigint NOT NULL REFERENCES users (id) ON DELETE CASCADE,
    step_date  date NOT NULL,
    steps      integer NOT NULL CHECK (steps >= 0),
    source     text NOT NULL DEFAULT 'health_connect',
    updated_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, step_date)
);
