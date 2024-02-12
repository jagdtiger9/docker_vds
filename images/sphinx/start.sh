#!/bin/sh
/usr/local/bin/wait-for-it.sh db:3306 -- indexer --config /etc/sphinxsearch/sphinx.conf --all \
&& searchd --nodetach
