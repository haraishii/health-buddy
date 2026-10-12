# Health Buddy API

Go + PostgreSQL backend for the Health Buddy app. It serves the reference data from the
Data Requirements Brief (Packages 1-7), user accounts (sign up / sign in), and the user's daily logs.

> **All seed data is DUMMY.** Every reference row has `source = 'DUMMY ...'`. The numbers only make
> the screens look plausible; they are not verified against TKPI, AKG, the Compendium or real labels.
> Replace them with the team's package files before release.

## Run it

**Option A: Docker** (no local Go or Postgres needed)

```bash
cd backend
docker compose up --build          # API on http://localhost:8080, Postgres on localhost:5432
docker compose run --rm api -reset -seed -no-serve   # start over from the SQL files
```

**Option B: local Go 1.22+ and your own Postgres 14+**

```bash
cd backend
cp .env.example .env               # edit DATABASE_URL if needed
set -a; . ./.env; set +a
go run ./cmd/api -seed             # migrate + load dummy data (once), then serve
go run ./cmd/api -reset -seed      # drop everything and reload
go test ./...
```

| Flag | Effect |
|---|---|
| `-migrate` | Apply pending files in `db/migrations/` |
| `-seed` | Also apply pending files in `db/seeds/` (dummy data, dev only) |
| `-reset` | Drop all tables first (dev only) |
| `-no-serve` | Exit after migrating/seeding |

Each SQL file runs once and is recorded in `schema_migrations` / `seed_runs`. To change the schema,
add a new file (`0003_...sql`); never edit a file that has already been applied.

### Using Supabase as the database

1. Create a project in a region close to your users and server (e.g. Singapore for Indonesia).
2. Dashboard → **Connect** → copy a pooler connection string into `DATABASE_URL` (see `.env.example`):
   - **Session pooler, port 5432**: for an API that stays running (your laptop, a VPS, Fly.io, Render, Railway).
   - **Transaction pooler, port 6543**: for serverless hosts; add `default_query_exec_mode=simple_protocol`.
   - Avoid the "Direct connection" (`db.<ref>.supabase.co`): it is IPv6-only, which most home networks and hosts cannot reach.
3. Run `go run ./cmd/api -seed -no-serve` once to create the tables, then start the API normally.

The API connects as the `postgres` user and owns the tables. Migration `0003_enable_rls.sql` turns on
Row Level Security with no policies, so Supabase's public REST API (anon key) cannot read anything,
including `users.password_hash`. **Every new table must also get `ENABLE ROW LEVEL SECURITY`.**
Do not give the app the Supabase keys; the app only talks to this API.

`-reset` drops only this app's tables, but it still deletes all their data: never run it on the production project.

The test logs cover the 14 days ending on the day you seed. Run `-reset -seed` again later to move them to the current date.

## Test accounts

Password for all three: `password123`

| Email | Scenario (brief, "Test data") |
|---|---|
| `annida@example.com` | Student: sleep ~1.5 h lower in week 2, protein below target, high stress on 3 days |
| `bima@example.com` | Active: exercise 5-6 days/week, regular meals, lower stress on exercise days |
| `citra@example.com` | Inactive: low steps, frequent fried snacks, water below target |

New accounts can be created with `POST /api/v1/auth/signup`.

## API

All bodies are JSON. Endpoints under `/me` need `Authorization: Bearer <token>` from sign up / sign in.
Dates are `YYYY-MM-DD`; the app should always send its own local date (`date`, `from`, `to`), since
an omitted date means "today" in the server's time zone.

| Method & path | Purpose | Screen |
|---|---|---|
| `POST /api/v1/auth/signup` | `{email, password, name}` → token + user | |
| `POST /api/v1/auth/signin` | `{email, password}` → token + user | |
| `GET /api/v1/me`, `PATCH /api/v1/me` | Profile; PATCH any of `name, status, birth_date, sex, height_cm, weight_kg, life_stage, steps_target` | Profile |
| `GET /api/v1/me/targets` | Daily goals from Package 5 by age, sex, life stage | Profile, Food, Home |
| `GET /api/v1/me/summary?date=` | Day totals, goal progress, latest stress | Home, Food |
| `GET /api/v1/me/analytics?from=&to=` | Per-day series, averages, % of targets, change vs previous period, insight numbers | Analytics, AI Insights |
| `GET/POST /api/v1/me/meals`, `DELETE .../{id}` | POST one of `food_id`, `barcode` or `custom{...}`, plus `meal_time`, `servings` | Food, Scan Meal |
| `GET/POST /api/v1/me/exercises`, `DELETE .../{id}` | `{activity_id, minutes}`; kcal = MET × weight × hours | Log Exercise |
| `GET/POST /api/v1/me/stress` | `{level 1-10, factor_ids[]}`; response includes Low/Medium/High | Stress Check |
| `POST /api/v1/me/water` | `{amount_ml}` (default 250) → day total | Home |
| `PUT /api/v1/me/sleep/{date}` | `{hours}`; date = morning the night ended | Home |
| `PUT /api/v1/me/steps/{date}` | `{steps}` from Health Connect / HealthKit | Home |
| `GET /api/v1/foods?q=&category=&limit=&offset=` | Search Package 1 (name, English name, aliases) with labels | Scan Meal (Search) |
| `GET /api/v1/foods/{id}` | One food with labels | |
| `GET /api/v1/products/{barcode}` | Package 2 lookup | Scan Meal (Barcode) |
| `GET /api/v1/activities?group=` | Package 3 with derived intensity | Log Exercise |
| `GET /api/v1/stress/questionnaire` | Package 4 questions, score bands, stress factors | Stress Check |
| `GET /api/v1/coach/content` | Package 7: tips, quick questions, restricted topics, reminders, insight templates | AI Coach, Home |
| `GET /healthz` | Database check | |

Example:

```bash
TOKEN=$(curl -s localhost:8080/api/v1/auth/signin \
  -d '{"email":"annida@example.com","password":"password123"}' | jq -r .token)
curl -s localhost:8080/api/v1/me/summary -H "Authorization: Bearer $TOKEN"
curl -s localhost:8080/api/v1/me/meals -H "Authorization: Bearer $TOKEN" \
  -d '{"meal_time":"lunch","food_id":"MK007","servings":1}'
```

## Schema compared with the brief

Column names follow the brief so the team's spreadsheets can be imported as-is. Additions:

| Table | Added | Why |
|---|---|---|
| `foods` | `name_en`, `aliases` | English UI; search by "nasgor" etc. |
| `packaged_products` | `product_group`, `serving_unit` | Per-group quota; the brief's `serving_size` has no unit |
| `activities` | `activity_group`, generated `intensity` | Maps the Log Exercise buttons + Light/Moderate/Hard to one MET row |
| `stress_score_bands` | `scale_min`, `scale_max` | Maps the daily 1-10 slider to Low/Medium/High |
| `stress_factors` | new table | The "What's on your mind?" chips |
| `nutrition_targets` | `life_stage`, `values_are_additions` | AKG lists pregnancy/breastfeeding as additions |
| `sleep_recommendations` | split out | Sleep bodies use different age groups than AKG |
| `app_defaults` | new table | Steps target (a developer decision, not in AKG) |
| `food_label_rules` | `nutrient`, `operator`, `basis` | So the app can evaluate the rule; drafts are ignored unless `ALLOW_DRAFT_LABEL_RULES=true` |
| `reminder_texts` | `kind` | Profile has daily, bedtime and weekly-summary switches |
| `insight_templates` | new table (7E) | Sentences for AI Insights with `{placeholders}` |

Not implemented on purpose: the Health Score (its weights are open question 4 in the brief) and
free-form AI Coach answers.
