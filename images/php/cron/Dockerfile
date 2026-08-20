ARG php_version
FROM jagdtiger/php-dev-env-git:php${php_version}
LABEL org.opencontainers.image.authors="gimatov@gmail.com"

# crond + database tools for dump/connect tasks; tzdata: TZ env requires zoneinfo on alpine
RUN apk add --no-cache --update busybox-suid mariadb-client mariadb-connector-c tzdata

COPY ./images/php/cron/entrypoint.sh /entrypoint.sh
COPY ./images/php/cron/dump-project /usr/local/bin/dump-project
RUN chmod +x /entrypoint.sh /usr/local/bin/dump-project

ENTRYPOINT ["/entrypoint.sh"]
CMD ["crond", "-f", "-l", "4", "-c", "/etc/crontabs", "-L", "/dev/stdout"]
