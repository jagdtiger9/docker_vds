# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Docker Compose-based development environment for PHP web applications with supporting services (MySQL/Percona, PostgreSQL, Redis, RabbitMQ, Nginx/Angie, Node.js WebSockets) and monitoring stack (Prometheus, Grafana, various exporters).

## Common Commands

```bash
# Initial setup
cp .env.example .env        # Local development
cp .env.prod .env           # Production server

# Start/stop services
make up                     # Start services with profile selection
make down                   # Stop services
make ps                     # Show running containers

# Build images
make build                  # Build with cache
make build.nocache          # Build without cache
make rebuild                # Full rebuild (removes volumes, pulls fresh)

# Run commands inside PHP container
make run CMD="yarn build"
make run CMD="cd public; yarn install"
make run PROJECT="other" CMD="composer install"  # Different project

# Initialize user in container (after first start)
make init

# Host configuration
make new.host HOST="domain.local"        # HTTP only
make new.host.https HOST="domain.com"    # HTTPS

# SSL certificates
make cert.create DOMAIN=example.com   # Create certificate
make cert.renew                       # Renew certificates
make cert.local.install                  # Install mkcert for local dev
make cert.local.create DOMAIN=app.local  # Create local certificate

# Reload proxy
make nginx.reload
make nginx_ws.reload
make caddy.reload

# Trust Caddy's local CA for dev on-demand TLS (once per machine)
make cert.local.caddy.trust

# Debug tools (phpMyAdmin, Buggregator)
make up.pma
make down.pma
```

## Architecture

### Compose Profiles

Services are organized into profiles (configured via `COMPOSE_PROFILES` in `.env`):
- `proxy` - Nginx/Angie without WebSocket ports (optionally + Caddy TLS edge)
- `proxy_ws` - Nginx/Angie with WebSocket support + Node.js (optionally + Caddy TLS edge)
- `main` - Core services: PHP-FPM, cron, workers, Redis, Memcached, RabbitMQ, Sphinx, syslog, logrotate
- `database` - Percona MySQL (omit if using host MySQL)
- `database_pg` - PostgreSQL 17 (opt-in; add to `COMPOSE_PROFILES` to enable)
- `metrics` - Prometheus, Grafana, exporters (node, nginx, mysql, postgres, redis, cadvisor)
- `pma` - phpMyAdmin + Adminer (MySQL and PostgreSQL web UIs)
- `debug` - Buggregator and debug tools
- `prod` - Production-only services (certbot)
- `logger` - Custom logger service

### Key Services

- **fpm** (php-fpm): PHP-FPM, static IP 192.168.17.25, built from `images/php-fpm/Dockerfile`, version controlled by `PHP_VERSION` (8.1-8.5)
- **cron** (cron): Cron jobs, reads tasks from `CONF_CRON` file
- **workers** (php-worker): Supervisord-managed workers, configs in `WORKER_CONFIG` directory
- **caddy**: Opt-in TLS edge (service lives in `compose.edge.yaml` — add that file to `COMPOSE_FILE` in `.env` to enable; static IP 192.168.17.26, host ports 80/443, profiles `proxy`/`proxy_ws`). On-demand certificates for tenant domains via one catch-all site + `ask` endpoint (`internal.ask.conf` on proxy:8081). Dev uses an internal CA (`make cert.local.caddy.trust`), prod Let's Encrypt (`Caddyfile.prod`). Instances without the edge file keep the classic schema (proxy publishes 80/443 itself). See the full plan in the Obsidian vault (Albion): "Caddy on-demand TLS".
- **proxy**: Web server (nginx or angie based on `PROXY_SERVER` env var); serves a maintenance stub (503 + `config/nginx/default_host/maintenance.html`) whenever php-fpm is unreachable. Publishes host 80/443 unless Caddy is enabled via `compose.edge.yaml`; `real_ip` trusts only 192.168.17.26
- **db**: Percona MySQL 8, static IP 192.168.17.33
- **pg**: PostgreSQL 17, static IP 192.168.17.34, profile `database_pg`
- **pgloader**: One-shot MySQL→PostgreSQL migration tool, profile `migrate` (`make pg.load DB=...`)
- **sphinx**: Full-text search, static IP 192.168.17.22

### Directory Structure

- `config/` - Service configurations (nginx, mysql, postgres, redis, prometheus, grafana, syslog, worker, cron)
- `data/` - Persistent data (mysql, postgres, redis, logs, grafana, prometheus, certbot certificates)
- `images/` - Custom Dockerfile builds (php-fpm, cron, php-worker, nodejs, sphinx)

### Network

All services on `192.168.17.0/24` subnet (bridge network `net`). Access host machine services from containers via `172.17.0.1`.

### User Permissions

Set `UID` and `GID` in `.env` to match host user (`id -u; id -g`). Container users are created automatically on startup or via `make init`.

## Documentation

For detailed installation and configuration instructions, see [docs/INSTALL.md](docs/INSTALL.md).
