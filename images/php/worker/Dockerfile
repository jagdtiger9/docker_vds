ARG php_version
FROM jagdtiger/php-dev-env-git:php${php_version}
LABEL org.opencontainers.image.authors="gimatov@gmail.com"

RUN apk add --update supervisor && rm  -rf /tmp/* /var/cache/apk/*

#ADD supervisord.conf /etc/
#ENTRYPOINT ["supervisord", "--nodaemon", "--configuration", "/etc/supervisord.conf"]

CMD ["/usr/bin/supervisord"]
