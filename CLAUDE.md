# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Docker Compose-based development environment for PHP web applications with supporting services (MySQL/Percona, Redis, RabbitMQ, Nginx/Angie, Node.js WebSockets) and monitoring stack (Prometheus, Grafana, various exporters).

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
make certbot.create DOMAIN=example.com   # Create certificate
make certbot.renew                       # Renew certificates
make cert.local.install                  # Install mkcert for local dev
make cert.local.create DOMAIN=app.local  # Create local certificate

# Reload proxy
make nginx.reload
make nginx_ws.reload

# Debug tools (phpMyAdmin, Buggregator)
make up.pma
make down.pma
```

## Architecture

### Compose Profiles

Services are organized into profiles (configured via `COMPOSE_PROFILES` in `.env`):
- `proxy` - Nginx/Angie without WebSocket ports
- `proxy_ws` - Nginx/Angie with WebSocket support + Node.js
- `main` - Core services: PHP-FPM, cron, workers, Redis, Memcached, RabbitMQ, Sphinx, syslog, logrotate
- `database` - Percona MySQL (omit if using host MySQL)
- `metrics` - Prometheus, Grafana, exporters (node, nginx, mysql, redis, cadvisor)
- `pma` - phpMyAdmin
- `debug` - Buggregator and debug tools
- `prod` - Production-only services (certbot)
- `logger` - Custom logger service

### Key Services

- **fpm** (php-fpm): PHP-FPM, built from `images/php-fpm/Dockerfile`, version controlled by `PHP_VERSION` (8.1-8.5)
- **crontab** (php-cron): Cron jobs, reads tasks from `CONF_CRON` file
- **workers** (php-worker): Supervisord-managed workers, configs in `CONF_WORKER` directory
- **proxy**: Web server (nginx or angie based on `PROXY_SERVER` env var)
- **db**: Percona MySQL 8, static IP 192.168.17.33
- **sphinx**: Full-text search, static IP 192.168.17.22

### Directory Structure

- `config/` - Service configurations (nginx, mysql, redis, prometheus, grafana, syslog, worker, cron)
- `data/` - Persistent data (mysql, redis, logs, grafana, prometheus, certbot certificates)
- `images/` - Custom Dockerfile builds (php-fpm, php-cron, php-worker, nodejs, sphinx)

### Network

All services on `192.168.17.0/24` subnet (bridge network `net`). Access host machine services from containers via `172.17.0.1`.

### Custom Compose Override

Use `COMPOSE_CUSTOM` env var to include project-specific compose file. Falls back to `custom-default.yaml`.

### User Permissions

Set `UID` and `GID` in `.env` to match host user (`id -u; id -g`). Container users are created automatically on startup or via `make init`.

## Documentation

For detailed installation and configuration instructions, see [docs/INSTALL.md](docs/INSTALL.md).
