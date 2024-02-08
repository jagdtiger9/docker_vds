ARG php_version
FROM jagdtiger/php-dev-env-git:php${php_version}
MAINTAINER gimatov@gmail.com

ARG allow_xdebug
ARG cron_config_dir

# Define host WWW-files owner user UID&GID
# http://stackoverflow.com/questions/23544282/what-is-the-best-way-to-manage-permissions-for-docker-shared-volumes
# https://github.com/phusion/baseimage-docker#running_startup_scripts
##RUN mkdir -p /etc/my_init.d
##ADD ./.conf/init_user_cron.sh /etc/my_init.d/init_user_cron.sh

# Add cron tasks
ADD $cron_config_dir /etc/cron.d/

RUN if [ "$allow_xdebug" = "0" ]; then phpdismod xdebug; fi
