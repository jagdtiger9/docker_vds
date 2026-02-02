ARG php_version
FROM jagdtiger/php-dev-env-git:php${php_version}
LABEL org.opencontainers.image.authors="gimatov@gmail.com"

ARG UID=33
ARG GID=33
ARG CRON_USER=www-data

# Install busybox-suid for crond to work with non-root users
RUN apk add --no-cache --update busybox-suid

# Create custom user/group
RUN addgroup -g ${GID} crongroup 2>/dev/null || true && \
    adduser -D -s /bin/bash -u ${UID} -G crongroup ${CRON_USER} 2>/dev/null || true

# Copy crontab - MUST be owned by root with 0600 permissions for busybox crond
COPY ./images/php/cron/vhosts_cron /etc/crontabs/${CRON_USER}
RUN chown root:root /etc/crontabs/${CRON_USER} && \
    chmod 0600 /etc/crontabs/${CRON_USER}

# Ensure /hosts_crontab is accessible (will be mounted)
RUN touch /hosts_crontab && chmod 755 /hosts_crontab

# crond: -f=foreground, -l 4=warning level, -c=crontabs dir, -L=log to stdout
CMD ["crond", "-f", "-l", "4", "-c", "/etc/crontabs", "-L", "/dev/stdout"]
