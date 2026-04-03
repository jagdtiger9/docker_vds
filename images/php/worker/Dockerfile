ARG php_version

FROM jagdtiger/php-dev-env-git:php${php_version}
LABEL org.opencontainers.image.authors="gimatov@gmail.com"

ARG uid=82
ARG gid=82
ARG worker=worker

RUN apk add --no-cache supervisor

# Create custom user/group
RUN addgroup -g ${gid} workergroup 2>/dev/null || true && \
    adduser -D -s /bin/bash -u ${uid} -G workergroup ${worker} 2>/dev/null || true

ADD ./images/php/worker/supervisord.conf /etc/

#ENTRYPOINT ["supervisord", "--nodaemon", "--configuration", "/etc/supervisord.conf"]
