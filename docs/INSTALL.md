# Installation & Configuration Guide

Docker Compose-based development environment for PHP web applications with multi-virtual host support.

## Table of Contents

- [Quick Start](#quick-start)
- [Environment Configuration](#environment-configuration)
- [Multi-Virtual Host Setup](#multi-virtual-host-setup)
- [Service Profiles](#service-profiles)
- [Common Operations](#common-operations)
- [Production Setup](#production-setup)

---

## Quick Start

### 1. Configure

```bash
# Create environment file
cp .env.example .env
```

#### 1.1. Set User Permissions

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

#### 1.2. Set Required Passwords

Edit `.env` and set secure passwords:

```ini
MYSQL_ROOT_PASSWORD=your_secure_password
RABBITMQ_USER=admin
RABBITMQ_PASSWORD=your_rabbitmq_password
GRAFANA_PASSWORD=your_grafana_password
MYSQL_EXPORTER_PASSWORD=your_exporter_password
```

### 2. Build and Start

```bash
# Build images
make build

# Start services
make up

# Verify running containers
make ps
```

### 3. Open default host

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

## Common Operations

```bash
curl -sL https://deb.nodesource.com/setup_22.x | sudo bash - \
&& sudo apt-get install -y nodejs \
&& sudo npm install -g corepack \
&& corepack enable \
&& yarn set version stable
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
