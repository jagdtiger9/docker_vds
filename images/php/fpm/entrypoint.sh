#!/bin/bash
set -e

echo "uid-gid: $WEB_UID:$WEB_GID"
echo "FPM_LOG_LEVEL: ${FPM_LOG_LEVEL}"

# Create group if GID doesn't exist
if ! getent group ${WEB_GID} > /dev/null 2>&1; then
    addgroup -g ${WEB_GID} g${WEB_GID}
fi
# Create user if UID doesn't exist
if ! getent passwd ${WEB_UID} > /dev/null 2>&1; then
    WEB_GROUP_NAME=$(getent group ${WEB_GID} | cut -d: -f1)
    adduser -s /bin/bash -u ${WEB_UID} -G ${WEB_GROUP_NAME} -D -H u${WEB_UID}
fi
# Get actual user/group names by UID/GID
WEB_NAME=$(getent passwd ${WEB_UID} | cut -d: -f1)
WEB_GROUP=$(getent group ${WEB_GID} | cut -d: -f1)
echo "www: ${WEB_NAME}:${WEB_GROUP} - ${WWW_CONF_PATH}"

WEB_NAME=www-data
WWB_GROUP=www-data

# Replace placeholders in www.conf
sed -i "s/\[WEB_NAME\]/${WEB_NAME}/g" ${WWW_CONF_PATH}
sed -i "s/\[WEB_GROUP\]/${WEB_GROUP}/g" ${WWW_CONF_PATH}
sed -i "s/\[FPM_LOG_LEVEL\]/${FPM_LOG_LEVEL}/g" ${PHP_FPM_PATH}

exec "$@"
