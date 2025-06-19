FROM phusion/baseimage:noble-1.0.2
MAINTAINER gimatov@gmail.com

#    && wget -O sphinx_latest https://sphx.org/files/sphinx-3.4.1-efbcc65-linux-amd64.tar.gz \

RUN apt-get --allow-releaseinfo-change -y update \
    && apt-get install -y wget \
    && apt-get install -y libgomp1 \
    && apt-get install -y php-fpm \
    && apt-get install -y libmysqlclient-dev \
    && wget -O sphinx_latest https://sphinxsearch.com/files/sphinx-3.8.1-d25e0bb-linux-amd64.tar.gz \
    && mkdir sphinxDir \
    && tar -xvzf ./sphinx_latest -C sphinxDir \
    && cp sphinxDir/sphinx-3.8.1/bin/indexer /usr/bin/indexer \
    && cp sphinxDir/sphinx-3.8.1/bin/indextool /usr/bin/indextool \
    && cp sphinxDir/sphinx-3.8.1/bin/searchd /usr/bin/searchd \
    && cp sphinxDir/sphinx-3.8.1/bin/wordbreaker /usr/bin/wordbreaker \
    && mkdir -p /etc/sphinxsearch /etc/default/sphinxsearch /var/log/sphinxsearch /var/lib/sphinxsearch/data \
    && rm -r sphinxDir

# Config files.
#RUN mkdir /etc/default
COPY ./images/sphinx3/conf/sphinxsearch /etc/default/sphinxsearch
COPY ./images/sphinx3/conf/sphinx.conf /etc/sphinxsearch/sphinx.conf
COPY ./images/sphinx3/conf/cron/indexer.sh /usr/local/bin/indexer.sh
COPY ./images/sphinx3/conf/cron/sphinx_indexer /etc/cron.d/sphinx_indexer
RUN chmod 0644 /etc/cron.d/sphinx_indexer
RUN mkdir /etc/service/sphinxsearch
ADD ./images/sphinx3/start.sh /etc/service/sphinxsearch/run
ADD ./images/sphinx3/conf/wait-for-it.sh /usr/local/bin/wait-for-it.sh

RUN ln -sf /dev/stderr /var/log/sphinxsearch/searchd.log \
    && ln -sf /dev/stdout /var/log/sphinxsearch/query.log

# Expose ports
EXPOSE 9312 9306

VOLUME ["/var/www"]

