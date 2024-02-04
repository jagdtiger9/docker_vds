ARG php_version
FROM jagdtiger/php-dev-env-git:php${php_version}
MAINTAINER gimatov@gmail.com

ARG allow_xdebug

ARG php_version
ENV php_version ${php_version:-8.1}

ARG FPM_LOG_LEVEL
ENV FPM_LOG_LEVEL ${FPM_LOG_LEVEL:-warning}

RUN echo "allow_xdebug: $allow_xdebug"
RUN echo "php_version: $php_version"

# Define host WWW-files owner user UID&GID
# http://stackoverflow.com/questions/23544282/what-is-the-best-way-to-manage-permissions-for-docker-shared-volumes
# https://github.com/phusion/baseimage-docker#running_startup_scripts
RUN mkdir -p /etc/my_init.d
#ADD ./.conf/init_user.sh /etc/my_init.d/init_user.sh

COPY ./config/fpm/php-fpm.conf /etc/php/${php_version}/fpm/php-fpm.conf
COPY ./config/fpm/www.conf /etc/php/${php_version}/fpm/pool.d/www.conf

RUN mkdir /etc/service/php-fpm
ADD ./config/fpm/start${php_version}.sh /etc/service/php-fpm/run

RUN if [ "$allow_xdebug" = "0" ]; then phpdismod xdebug; fi

EXPOSE 9000
