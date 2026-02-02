ARG php_version

FROM jagdtiger/php-dev-env-git:php${php_version}
LABEL org.opencontainers.image.authors="gimatov@gmail.com"

RUN apk add --no-cache supervisor

ADD ./images/php/worker/supervisord.conf /etc/

#ENTRYPOINT ["supervisord", "--nodaemon", "--configuration", "/etc/supervisord.conf"]
