FROM phusion/baseimage:jammy-1.0.1
MAINTAINER gimatov@gmail.com

COPY server /var/www

RUN apt-get -y update \
    && apt-get install -y curl \
    && curl -sL https://deb.nodesource.com/setup_14.x | bash - \
    && apt-get install -y nodejs \
    && cd /var/www \
    && npm install \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Expose ports
EXPOSE 8085 1333

VOLUME ["/var/www"]

CMD ["node", "/var/www/server.js"]
