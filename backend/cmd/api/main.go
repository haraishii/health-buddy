// Command api runs the Health Buddy HTTP API.
//
//	go run ./cmd/api -migrate          # create or update tables, then serve
//	go run ./cmd/api -reset -seed      # dev: drop everything, recreate, load dummy data, then serve
//	go run ./cmd/api -migrate -no-serve
package main

import (
	"context"
	"errors"
	"flag"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/iwinardhyas/health-buddy/backend/db"
	"github.com/iwinardhyas/health-buddy/backend/internal/api"
	"github.com/iwinardhyas/health-buddy/backend/internal/config"
)

func main() {
	migrate := flag.Bool("migrate", false, "apply pending migrations before starting")
	seed := flag.Bool("seed", false, "load dummy reference data and test users (implies -migrate)")
	reset := flag.Bool("reset", false, "DROP ALL TABLES first (implies -migrate); development only")
	noServe := flag.Bool("no-serve", false, "exit after migrate/seed instead of starting the server")
	flag.Parse()
	// On hosts without a shell (e.g. Render's free plan), SEED_DUMMY_DATA=true does the same as -seed.
	// Seed files are recorded once applied, so leaving it on does not insert the data twice.
	if os.Getenv("SEED_DUMMY_DATA") == "true" {
		*seed = true
	}

	cfg, err := config.Load()
	if err != nil {
		log.Fatal(err)
	}

	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	pool, err := pgxpool.New(ctx, cfg.DatabaseURL)
	if err != nil {
		log.Fatal(err)
	}
	defer pool.Close()
	if err := pool.Ping(ctx); err != nil {
		log.Fatalf("cannot reach database: %v", err)
	}

	if *reset {
		log.Print("dropping all tables")
		if err := db.Reset(ctx, pool); err != nil {
			log.Fatal(err)
		}
	}
	if *migrate || *seed || *reset {
		if err := db.Migrate(ctx, pool); err != nil {
			log.Fatal(err)
		}
	}
	if *seed {
		if err := db.Seed(ctx, pool); err != nil {
			log.Fatal(err)
		}
	}
	if *noServe {
		return
	}

	srv := &http.Server{
		Addr:              ":" + cfg.Port,
		Handler:           api.NewServer(pool, cfg).Routes(),
		ReadHeaderTimeout: 10 * time.Second,
		ReadTimeout:       30 * time.Second,
		WriteTimeout:      30 * time.Second,
	}
	go func() {
		log.Printf("listening on :%s", cfg.Port)
		if err := srv.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			log.Fatal(err)
		}
	}()

	<-ctx.Done()
	log.Print("shutting down")
	shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := srv.Shutdown(shutdownCtx); err != nil {
		log.Print(err)
	}
}
