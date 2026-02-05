# Installation & Configuration Guide

Docker Compose-based development environment for PHP web applications with multi-virtual host support.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Environment Configuration](#environment-configuration)
- [Multi-Virtual Host Setup](#multi-virtual-host-setup)
- [Service Profiles](#service-profiles)
- [Common Operations](#common-operations)
- [Production Setup](#production-setup)

---

## Prerequisites

- Docker Engine 20.10+
- Docker Compose v2+
- GNU Make
- For local HTTPS: mkcert

```bash
# Check versions
docker --version
docker compose version
```

---

## Quick Start

### 1. Clone and Configure

```bash
# Make and enter Docker working directory
cd ~/work/Docker
# Clone repository
git clone <repository-url> .

# Create environment file
cp .env.example .env
```

### 2. Set User Permissions

Get your user/group IDs and update `.env`:

```bash
# Get your UID and GID
id -u  # e.g., 1000
id -g  # e.g., 1000
```

Edit `.env`:
```ini
UID=1000
GID=1000
```

### 3. Set Required Passwords

Edit `.env` and set secure passwords:

```ini
MYSQL_ROOT_PASSWORD=your_secure_password
RABBITMQ_USER=admin
RABBITMQ_PASSWORD=your_rabbitmq_password
GRAFANA_PASSWORD=your_grafana_password
MYSQL_EXPORTER_PASSWORD=your_exporter_password
```

### 4. Build and Start

```bash
# Build images
make build

# Start services
make up

# Verify running containers
make ps
```

### 5. Open default host

```
http://localhost/
```

---

## Virtual Host Setup

### Config

Define virtual host parameters in .env

```
DATA_HOSTS=...path_to_your_host_project_files...
CONF_HOSTS=...path_to_you_host_config_giles...
```

Example:
```
DATA_HOSTS=./data/www/
CONF_HOSTS=./data/config/hosts/
```

### Directory Structure



```
[DATA_HOSTS]                 # DATA_HOSTS - all projects root
├── site1.local/
│   └── public/              # Document root
│       └── index.php
├── site2.local/
│   └── public/
│       └── index.php
└── magicpro.local/
    └── public/
        └── index.php

[CONF_HOSTS]                 # CONF_HOSTS - nginx configs
├── site1.local.conf
├── site2.local.conf
└── magicpro.local.conf
```

### Adding a New Virtual Host

#### Local Development (HTTP)

```bash
# 1. Create nginx config
make new.host HOST="magicpro.local"

or create it manually and place in the [CONF_HOSTS] directory

# 2. Create project directory
mkdir -p [DATA_HOSTS]/magicpro.local/public

# 3. Create index.php
echo '<?php phpinfo();' > [DATA_HOSTS]/magicpro.local/public/index.php

# 4. Add to /etc/hosts
echo "127.0.0.1 magicpro.local" | sudo tee -a /etc/hosts

# 5. Reload nginx
make nginx.reload
```

#### Production (HTTPS with Let's Encrypt)

```bash
# 1. Create nginx config (HTTPS template)
make new.host.https HOST="example.com"

# 2. Create project directory
mkdir -p [DATA_HOSTS]/example.com/public

# 3. Temporarily configure for certbot (edit config)
# Comment out SSL lines, keep only port 80 with acme-challenge

# 4. Reload and create certificate
make nginx.reload
make certbot.create DOMAIN=example.com

# 5. Uncomment SSL lines in config and reload
make nginx.reload
```

#### Local Development (HTTPS with mkcert)

```bash
# 1. Install mkcert (one-time)
make cert.local.install

# 2. Create certificate
make cert.local.create DOMAIN=magicpro.local

# 3. Create nginx config with HTTPS
make new.host.https HOST="magicpro.local"

# 4. Update config to use local certificates
# Edit config/nginx/hosts/magicpro.local.conf:
#   ssl_certificate /etc/nginx/ssl/magicpro.local.crt;
#   ssl_certificate_key /etc/nginx/ssl/magicpro.local.key;
```

### Virtual Host Config Templates

#### HTTP Only (development)
Location: `config/nginx/hosts/default.host.conf_http`

```nginx
server {
    listen 80;
    http2 on;
    root /var/www/[DOMAIN_NAME]/public;
    index index.php index.html;
    server_name [DOMAIN_NAME];

    location / {
        try_files $uri $uri/ /index.php$is_args$query_string;
    }

    location ~ \.php$ {
        try_files $uri =404;
        fastcgi_pass php_fpm;
        include fastcgi_params;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
```

#### HTTPS (production)
Location: `config/nginx/hosts/default.host.conf_https`

Includes HTTP→HTTPS redirect, www→non-www redirect, and SSL configuration.

---

## Service Profiles

Select which services to run via `COMPOSE_PROFILES`:

| Profile | Services | Use Case |
|---------|----------|----------|
| `proxy` | Nginx/Angie (no WS ports) | Production without WebSockets |
| `proxy_ws` | Nginx/Angie + WebSocket ports + Node.js | WebSocket support |
| `main` | PHP-FPM, Cron, Workers, Redis, Memcached, RabbitMQ, Sphinx, Syslog, Logrotate | Core services |
| `database` | Percona MySQL 8 | Use if not using host MySQL |
| `metrics` | Prometheus, Grafana, Node/Nginx/MySQL/Redis exporters, cAdvisor | Monitoring |
| `pma` | phpMyAdmin | Database management UI |
| `debug` | Buggregator | Debug tools |
| `prod` | Certbot | SSL certificate management |
| `logger` | Custom logger service | Application logging |

### Profile Combinations

**Development:**
```ini
COMPOSE_PROFILES=proxy_ws,main,database,metrics,pma,debug
```

**Production (minimal):**
```ini
COMPOSE_PROFILES=proxy_ws,main,database,prod
```

**Production (with monitoring):**
```ini
COMPOSE_PROFILES=proxy_ws,main,database,metrics,prod
```

**Using host MySQL:**
```ini
# Omit 'database' profile
COMPOSE_PROFILES=proxy_ws,main,metrics,pma
```

---

## Common Operations

### Container Management

```bash
make up              # Start services
make down            # Stop services
make ps              # List running containers
make build           # Rebuild images (with cache)
make build.nocache   # Rebuild images (no cache)
make rebuild         # Full rebuild (removes volumes)
```

### Running Commands in PHP Container

```bash
# Run in default project
make run CMD="composer install"
make run CMD="yarn build"
make run CMD="php artisan migrate"

# Run in specific project
make run PROJECT="api" CMD="composer install"

# Run in specific service
make run.cmd SERVICE="workers" CMD="supervisorctl status"
```

### Nginx Operations

```bash
make nginx.reload      # Reload nginx config
make nginx_ws.reload   # Reload nginx with WebSocket support
```

### SSL Certificates

```bash
# Let's Encrypt (production)
make certbot.create DOMAIN=example.com
make certbot.renew
make certbot.renew.dry    # Test renewal

# Local development (mkcert)
make cert.local.install   # Install mkcert
make cert.local.create DOMAIN=magicpro.local
```

### Debug Tools

```bash
make up.pma          # Start phpMyAdmin + Buggregator
make down.pma        # Stop debug tools
```

---

## Network Configuration

All services are on subnet `192.168.17.0/24`:

| Service | IP Address | Port |
|---------|------------|------|
| MySQL (db) | 192.168.17.33 | 3306 |
| Sphinx | 192.168.17.22 | 9312, 9306 |
| Host machine | 172.17.0.1 | - |

Access services from containers using hostnames:
- `db` - MySQL
- `redis` - Redis
- `memcached` - Memcached
- `rabbitmq` - RabbitMQ
- `sphinx` - Sphinx

---

## Port Mapping

| Service | Host Port | Container Port |
|---------|-----------|----------------|
| HTTP | 80 | 80 |
| HTTPS | 443 | 443 |
| MySQL | 33006 | 3306 |
| phpMyAdmin | 8081 | 80 |
| WebSocket HTTP | 8085 | 8085 |
| WebSocket HTTPS | 8485 | 8485 |
| WebSocket | 8033 | 8033 |
| WebSocket SSL | 8433 | 8433 |
| Prometheus | 9090 | 9090 |
| Buggregator | 8000 | 8000 |
| Angie status | 8099 | 8099 |

---

## Troubleshooting

### Permission Issues

```bash
# Re-run permission setup
make perms

# Initialize user in container
make init
```

### Container User Mismatch

Ensure `UID` and `GID` in `.env` match your host user:
```bash
id -u  # Should match UID
id -g  # Should match GID
```

### MySQL Connection from Host

Enable port mapping in `.env`:
```ini
DB_PORT_MAP=33006:3306
```

Connect:
```bash
mysql -h 127.0.0.1 --port=33006 --protocol=tcp -u root -p
```

### View Container Logs

```bash
# Via docker
docker logs php-fpm
docker logs proxy

# Aggregated logs (if syslog enabled)
tail -f data/log/*.log
```

### Rebuild Single Service

```bash
docker compose build --no-cache fpm
docker compose up -d fpm
```
