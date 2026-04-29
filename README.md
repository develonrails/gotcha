# Gotcha

Self-hosted error and performance monitoring for Ruby/Rails applications. Compatible with the [Sentry SDK](https://docs.sentry.io/platforms/ruby/) protocol — use `sentry-ruby` and `sentry-rails` gems as clients.

## Features

- **Error tracking** with fingerprint-based deduplication, occurrence counts, and resolved/ignored/unresolved states. Atomic upserts (Postgres `INSERT ... ON CONFLICT`) so concurrent ingests of the same fingerprint never duplicate.
- **Performance monitoring** with p50/p95/p99 latency (computed in SQL), slow-query and N+1 hotspot detection, and per-transaction throughput over time.
- **Multi-project support** with per-project DSN keys and configurable retention (30 / 60 / 90 / 180 / 365 days). The DSN auth lookup on the ingest hot path is cached in SolidCache.
- **Alert routing** to Slack, Discord, Email, and generic webhooks, with throttling per fingerprint to prevent floods.
- **Sentry SDK compatibility** — drops in as the DSN target for `sentry-rails`; no client changes required.
- **Optional credential encryption** for alert channel configs when `ActiveRecord::Encryption` is configured.
- **Substring-indexed error search** via `pg_trgm` GIN indexes — `ILIKE '%X%'` queries are index-served, not table scans.

## Quick Start

```bash
curl -sL https://raw.githubusercontent.com/develonrails/gotcha/main/docker-compose.yml -o docker-compose.yml
docker compose up -d
```

The dashboard will be available at `http://your-server-ip`. Create a project to get a DSN.

For production, set your own `SECRET_KEY_BASE` and optional HTTP basic auth in the compose file or via environment variables.

## Client Configuration

In your Rails application:

```ruby
# Gemfile
gem "sentry-ruby"
gem "sentry-rails"

# config/initializers/sentry.rb
Sentry.init do |config|
  config.dsn = "http://<dsn_key>@<gotcha-host>/<project_id>"
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  config.traces_sample_rate = 1.0
end
```

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `SECRET_KEY_BASE` | No | Built-in default | Rails secret key (override with `openssl rand -hex 64` for production) |
| `GOTCHA_HOST` | No | `localhost` | Host shown in DSN URLs |
| `GOTCHA_USERNAME` | No | — | HTTP basic auth username (empty = no auth) |
| `GOTCHA_PASSWORD` | No | — | HTTP basic auth password |
| `JOB_CONCURRENCY` | No | `2` | SolidQueue worker process count (each runs 3 threads) |
| `PORT` | No | `80` | Port to expose the web UI |

## Architecture

```
sentry-rails SDK  →  POST /api/:project_id/envelope/
                            ↓
                     IngestController (DSN auth, SolidCache-backed lookup)
                            ↓
                     PersistErrorJob / PersistPerformanceJob (SolidQueue)
                            ↓
                     PostgreSQL (atomic UPSERT keyed on project_id + fingerprint)
                            ↓
                     AlertJob → Slack / Discord / Email / Webhook
                                  (throttled per fingerprint via SolidCache)
```

## Stack

- Ruby 4.0 / Rails 8.1
- PostgreSQL 18 (requires `pg_trgm` extension — installed automatically by migration)
- SolidQueue for background jobs
- SolidCache for DSN lookups and alert throttling
- Thruster for HTTP

## Deploying

The `pg_trgm` extension is created automatically by migration `20260429000004`. On managed Postgres providers (RDS, Cloud SQL, etc.) the first `CREATE EXTENSION` requires superuser; you may need a one-time DBA action. Subsequent deploys are no-ops.

For Kamal, see `config/deploy.yml`. For docker-compose, the included file builds a complete stack with Postgres.

If you bump `JOB_CONCURRENCY` above 2, make sure your Postgres `max_connections` has headroom — each worker process opens its own pool.

## Development

```bash
# Open in VS Code with devcontainer, or:
cd .devcontainer && docker compose up -d
# Enter the container
deventer gotcha
# Setup and run
bin/setup
bin/dev
```

## Origin

Originally based on [ITSSOUMIT/findbug](https://github.com/ITSSOUMIT/findbug) by [Soumit Das](https://github.com/ITSSOUMIT) — a Rails engine for embedded error tracking. We converted it into a standalone self-hosted service and added multi-project support, the Sentry envelope protocol for ingestion, configurable per-project retention, and alert routing.

## License

MIT
