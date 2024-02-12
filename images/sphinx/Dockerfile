FROM phusion/baseimage:jammy-1.0.1
MAINTAINER gimatov@gmail.com

RUN apt-get -y update \
    && apt-get install -y sphinxsearch \
    && apt-get install -y php \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

#RUN apt-get update && apt-get upgrade -y -o Dpkg::Options::="--force-confold"

# Config files.
COPY conf/sphinxsearch /etc/default/sphinxsearch
COPY conf/sphinx.conf /etc/sphinxsearch/sphinx.conf
COPY conf/cron/indexer.sh /usr/local/bin/indexer.sh
COPY conf/cron/sphinx_indexer /etc/cron.d/sphinx_indexer
RUN chmod 0644 /etc/cron.d/sphinx_indexer

RUN ln -sf /dev/stderr /var/log/sphinxsearch/searchd.log \
    && ln -sf /dev/stdout /var/log/sphinxsearch/query.log

# Expose ports
EXPOSE 9312 9306

VOLUME ["/var/www"]

RUN mkdir /etc/service/sphinxsearch
ADD start.sh /etc/service/sphinxsearch/run
ADD conf/wait-for-it.sh /usr/local/bin/wait-for-it.sh
