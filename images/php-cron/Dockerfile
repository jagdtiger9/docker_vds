ARG php_version
FROM jagdtiger/php-dev-env-git:php${php_version}
MAINTAINER gimatov@gmail.com

ARG allow_xdebug

# Define host WWW-files owner user UID&GID
# http://stackoverflow.com/questions/23544282/what-is-the-best-way-to-manage-permissions-for-docker-shared-volumes
# https://github.com/phusion/baseimage-docker#running_startup_scripts

RUN if [ "$allow_xdebug" = "0" ]; then phpdismod xdebug; fi

COPY ./images/php-cron/vhosts_cron  /etc/cron.d/vhosts_cron
RUN chmod 0644 /etc/cron.d/vhosts_cron
