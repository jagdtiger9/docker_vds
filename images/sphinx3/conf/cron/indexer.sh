#!/bin/bash

echo "result=" >> /var/www/magicpro/public/vardata/log/indexer.log

/usr/bin/indexer --all --rotate --config /etc/sphinxsearch/sphinx.conf >> /var/www/magicpro/public/vardata/log/indexer.log

echo "" >> /var/www/magicpro/public/vardata/log/indexer.log
echo "" >> /var/www/magicpro/public/vardata/log/indexer.log
