ARG PHP_VERSION=8.3

# Based on official PHP FPM Alpine image
FROM php:${PHP_VERSION}-fpm-alpine3.21
LABEL org.opencontainers.image.authors="gimatov@gmail.com"

ARG PHP_VERSION

# Install runtime dependencies
RUN apk add --no-cache \
    rabbitmq-c \
    libmemcached-libs \
    imagemagick \
    imagemagick-libs \
    libgomp \
    libwebp \
    libjpeg-turbo \
    libpng \
    freetype \
    libxpm \
    icu-libs \
    libzip \
    oniguruma \
    gmp \
    libxml2 \
    bash \
    git \
    unzip \
    mysql-client \
    make \
    sqlite \
    nodejs \
    npm \
    yarn

# Install PHP core extensions and PECL extensions in single layer
# https://hub.docker.com/_/php
# https://github.com/mlocati/docker-php-extension-installer
RUN set -eux; \
    apk add --no-cache --virtual .build-deps \
        $PHPIZE_DEPS \
        linux-headers \
        icu-dev \
        libzip-dev \
        libpng-dev \
        libjpeg-turbo-dev \
        freetype-dev \
        libwebp-dev \
        libxpm-dev \
        gmp-dev \
        oniguruma-dev \
        openssl-dev \
        sqlite-dev \
        libxml2-dev \
        rabbitmq-c-dev \
        libmemcached-dev \
        zlib-dev \
        imagemagick-dev \
        libtool \
    ; \
    docker-php-ext-configure gd \
        --with-freetype \
        --with-jpeg \
        --with-webp \
        --with-xpm \
    ; \
    curl -sSLf \
            -o /usr/local/bin/install-php-extensions \
            https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions && \
        chmod +x /usr/local/bin/install-php-extensions && \
    install-php-extensions \
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
    ; \
# Rotator
#COPY conf/xdebug.ini conf/rotator_8.tgz* /tmp
#RUN if [ ${ADD_ROTATOR} && -f "/tmp/rotator_8.tgz" ]; then tar -zxf /tmp/rotator_8.tgz -C /tmp \
#    && cd /tmp \
#    && ls -la \
#    && cd rotator_8 \
#    && phpize \
#    && ./configure \
#    && make && make install \
#    && cd ../ \
#    && rm -r rotator_8 rotator_8.tgz \
#    && cd ../ \
#    && cat > /etc/php/${PHP_VERSION}/mods-available/rotator.ini \
#    && echo "extension=rotator.so" > /etc/php/${PHP_VERSION}/mods-available/rotator.ini \
#    && phpenmod rotator ; fi

#    docker-php-ext-install -j$(nproc) \
#        bcmath \
#    ; \
#    pecl install \
#        apcu \
#    ; \
#    docker-php-ext-enable \
#        apcu \
#    ; \
    apk del --no-network .build-deps; \
    rm -rf /tmp/* /var/cache/apk/*

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
