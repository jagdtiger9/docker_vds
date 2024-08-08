FROM phusion/baseimage:jammy-1.0.1
MAINTAINER gimatov@gmail.com

#ENV WS_PORT ${WS_PORT:-1333}
#ENV WS_HTTP_PORT ${WS_HTTP_PORT:-8085}

RUN apt-get -y update \
    && apt-get install -y curl git \
    && curl -sL https://deb.nodesource.com/setup_18.x | bash - \
    && install_clean nodejs \
    && corepack enable \
    && mkdir /var/www && cd /var/www \
    && git clone https://github.com/jagdtiger9/wss_server . \
    && yarn install \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Expose ports
#EXPOSE ${WS_PORT} ${WS_HTTP_PORT}

VOLUME ["/var/www"]

CMD ["node", "/var/www/server.js"]
