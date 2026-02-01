FROM node:18-alpine
LABEL org.opencontainers.image.authors="gimatov@gmail.com"m

RUN apk add --no-cache curl git \
    && corepack enable \
    && mkdir /var/www && cd /var/www \
    && git clone https://github.com/jagdtiger9/wss_server . \
    && yarn install \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Expose ports
#EXPOSE ${WS_PORT} ${WS_HTTP_PORT}

VOLUME ["/var/www"]

CMD ["node", "/var/www/server.js"]
