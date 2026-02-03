ARG PHP_VERSION=8.3

# Based on official PHP FPM Alpine image
FROM php:${PHP_VERSION}-fpm-alpine3.21
LABEL org.opencontainers.image.authors="gimatov@gmail.com"

# Install PHP extensions and runtime tools in single layer
# install-php-extensions handles build deps automatically and cleans up after itself
# https://github.com/mlocati/docker-php-extension-installer
RUN set -eux; \
    curl -sSLf -o /usr/local/bin/install-php-extensions \
        https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions \
    && chmod +x /usr/local/bin/install-php-extensions \
    && install-php-extensions \
        bcmath \
        exif \
        gd \
        gmp \
        intl \
        ffi \
        xsl \
        gettext \
        msgpack \
        pcntl \
        shmop \
        sysvmsg \
        sysvsem \
        sysvshm \
        opcache \
        pdo_mysql \
        pdo_sqlite \
        sockets \
        zip \
        apcu \
        amqp \
        memcached \
        imagick \
        redis \
        igbinary \
        xhprof \
    && rm /usr/local/bin/install-php-extensions \
    && ln -s /usr/local/bin/php /usr/bin/php

# Install only runtime tools not provided by extensions
RUN apk add --no-cache \
    bash \
    git \
    unzip \
    mysql-client \
    make \
    sqlite \
    nodejs \
    npm \
    yarn \
    && npm install -g corepack \
    && corepack enable \
    && rm -rf /var/cache/apk/*

# Install Composer from official image
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Config files
COPY conf/php8.ini $PHP_INI_DIR/php.ini
COPY conf/php8-cli.ini $PHP_INI_DIR/php-cli.ini
COPY conf/xdebug.ini $PHP_INI_DIR/conf.d/docker-php-ext-xdebug.ini
COPY conf/xhproof.ini $PHP_INI_DIR/conf.d/docker-php-ext-xhprof.ini
COPY conf/opcache.ini $PHP_INI_DIR/conf.d/docker-php-ext-opcache.ini
COPY conf/apcu.ini $PHP_INI_DIR/conf.d/docker-php-ext-apcu.ini
COPY conf/memcached.ini $PHP_INI_DIR/conf.d/docker-php-ext-memcached.ini

WORKDIR /var/www
