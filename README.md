# Findbug

Self-hosted error and performance monitoring for Ruby/Rails applications. Compatible with the [Sentry SDK](https://docs.sentry.io/platforms/ruby/) protocol — use `sentry-ruby` and `sentry-rails` gems as clients.

## Origin

Originally based on [ITSSOUMIT/findbug](https://github.com/ITSSOUMIT/findbug) by [Soumit Das](https://github.com/ITSSOUMIT) — a Rails engine for embedded error tracking. We converted it into a standalone self-hosted service, adding:

- **Multi-project support** — Monitor multiple applications from a single Findbug instance via DSN-based project separation
- **Sentry SDK compatibility** — Receives data via the standard Sentry envelope protocol (`POST /api/:project_id/envelope/`), so you can use the official `sentry-rails` gem as a client
- **Independent deployment** — Runs as its own Docker Compose stack with PostgreSQL

## Quick Start

```bash
curl -sL https://raw.githubusercontent.com/develonrails/standalone-findbug/main/docker-compose.yml -o docker-compose.yml
docker compose up -d
```

The dashboard will be available at `http://your-server-ip`. Create a project to get a DSN.

For production, set your own secret key and optional auth in the compose file or via environment variables.

## Client Configuration

In your Rails application:

```ruby
# Gemfile
gem "sentry-ruby"
gem "sentry-rails"

# config/initializers/sentry.rb
Sentry.init do |config|
  config.dsn = "http://<dsn_key>@<findbug-host>/<project_id>"
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]
  config.traces_sample_rate = 1.0
end
```

## Environment Variables

| Variable | Required | Default | Description |
|----------|----------|---------|-------------|
| `SECRET_KEY_BASE` | No | Built-in default | Rails secret key (override with `openssl rand -hex 64` for production) |
| `FINDBUG_HOST` | No | `localhost` | Host shown in DSN URLs |
| `FINDBUG_USERNAME` | No | — | HTTP basic auth username (empty = no auth) |
| `FINDBUG_PASSWORD` | No | — | HTTP basic auth password |
| `PORT` | No | `80` | Port to expose the web UI |

## Architecture

```
sentry-rails SDK  →  POST /api/:project_id/envelope/
                            ↓
                     IngestController (authenticate DSN, parse envelope)
                            ↓
                     PersistErrorJob / PersistPerformanceJob (via SolidQueue)
                            ↓
                     PostgreSQL (error_events, performance_events)
                            ↓
                     AlertJob → Slack / Discord / Email / Webhook
```

## Stack

- Ruby 3.4 / Rails 8.1
- PostgreSQL 18
- SolidQueue for background jobs
- SolidCache for caching
- Thruster for HTTP

## Development

```bash
# Open in VS Code with devcontainer, or:
cd .devcontainer && docker compose up -d
# Enter the container
deventer findbug
# Setup and run
bin/setup
bin/dev
```

## License

MIT
