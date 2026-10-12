// Package db applies the SQL files in migrations/ and seeds/ in file-name order.
// Each file runs once in its own transaction and is recorded so it is not applied twice.
package db

import (
	"context"
	"embed"
	"fmt"
	"io/fs"
	"log"
	"sort"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

//go:embed migrations/*.sql
var migrations embed.FS

//go:embed seeds/*.sql
var seeds embed.FS

// Migrate creates or updates the schema.
func Migrate(ctx context.Context, pool *pgxpool.Pool) error {
	return apply(ctx, pool, migrations, "migrations", "schema_migrations")
}

// Seed loads the dummy reference data and test users. Development only.
func Seed(ctx context.Context, pool *pgxpool.Pool) error {
	return apply(ctx, pool, seeds, "seeds", "seed_runs")
}

// appTables lists every table this app creates. Reset drops only these, so it is safe on Supabase,
// where the public schema also carries grants and objects that Supabase itself manages.
// Add new tables here when a migration creates them.
var appTables = []string{
	"meal_logs", "exercise_logs", "stress_logs", "water_logs", "sleep_logs", "step_logs", "users",
	"foods", "packaged_products", "activities", "stress_questions", "stress_score_bands", "stress_factors",
	"nutrition_targets", "sleep_recommendations", "daily_intake_limits", "activity_recommendations",
	"app_defaults", "food_label_rules", "coach_tips", "coach_quick_questions", "coach_restricted_topics",
	"reminder_texts", "insight_templates", "schema_migrations", "seed_runs",
}

// Reset drops the app's tables and all their data. Development only.
func Reset(ctx context.Context, pool *pgxpool.Pool) error {
	_, err := pool.Exec(ctx, "DROP TABLE IF EXISTS "+strings.Join(appTables, ", ")+" CASCADE")
	return err
}

func apply(ctx context.Context, pool *pgxpool.Pool, files embed.FS, dir, table string) error {
	if _, err := pool.Exec(ctx, fmt.Sprintf(
		"CREATE TABLE IF NOT EXISTS %[1]s (name text PRIMARY KEY, applied_at timestamptz NOT NULL DEFAULT now());"+
			"ALTER TABLE %[1]s ENABLE ROW LEVEL SECURITY;",
		table)); err != nil {
		return err
	}

	names, err := fs.Glob(files, dir+"/*.sql")
	if err != nil {
		return err
	}
	sort.Strings(names)

	for _, name := range names {
		var done bool
		if err := pool.QueryRow(ctx, fmt.Sprintf("SELECT EXISTS (SELECT 1 FROM %s WHERE name = $1)", table), name).
			Scan(&done); err != nil {
			return err
		}
		if done {
			continue
		}

		sql, err := files.ReadFile(name)
		if err != nil {
			return err
		}
		err = pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
			// No arguments, so pgx sends the file with the simple protocol and multiple statements work.
			if _, err := tx.Exec(ctx, string(sql)); err != nil {
				return err
			}
			_, err := tx.Exec(ctx, fmt.Sprintf("INSERT INTO %s (name) VALUES ($1)", table), name)
			return err
		})
		if err != nil {
			return fmt.Errorf("%s: %w", name, err)
		}
		log.Printf("applied %s", name)
	}
	return nil
}
