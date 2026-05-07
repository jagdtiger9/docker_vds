ARG LOGROTATE_VERSION=latest
FROM blacklabelops/logrotate:${LOGROTATE_VERSION}

ARG CONTAINER_UID=1000
ARG CONTAINER_GID=1000

RUN apk add --no-cache shadow && \
    groupmod -g ${CONTAINER_GID} logrotate && \
    usermod -u ${CONTAINER_UID} logrotate
