ARG php_version
FROM jagdtiger/php-dev-env-git:php${php_version}
MAINTAINER gimatov@gmail.com

#ARG user

RUN apt-get -y update \
    && apt-get install -y software-properties-common \
    && apt-get install -y supervisor \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#CMD ["/usr/bin/supervisord", '-u', user]
CMD ["/usr/bin/supervisord"]
