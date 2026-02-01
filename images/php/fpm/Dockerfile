ARG php_version
FROM jagdtiger/php-dev-env-git:php${php_version}
LABEL org.opencontainers.image.authors="gimatov@gmail.com"

# Build cycle
ARG allow_xdebug
ARG php_version
ARG www_conf_path="/etc/php/fpm/pool.d/www.conf"
ARG php_fpm_path="/etc/php/fpm/php-fpm.conf"

# Container RUN cycle
ENV WWW_CONF_PATH=${www_conf_path}
ENV PHP_FPM_PATH=${php_fpm_path}

RUN echo "allow_xdebug: $allow_xdebug"
RUN echo "php_version: $php_version"

COPY ./config/fpm/php-fpm.conf ${php_fpm_path}
COPY ./config/fpm/www.conf ${www_conf_path}

#RUN if [ "$allow_xdebug" = "0" ]; then phpdismod xdebug; fi
RUN if [ "$allow_xdebug" = "1" ]; then install-php-extensions xdebug; fi

EXPOSE 9000

COPY --chmod=755 ./images/php/fpm/entrypoint.sh /entrypoint.sh
#RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["php-fpm"]
