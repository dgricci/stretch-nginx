#!/bin/bash

## Nginx web service

# Exit on any non-zero status.
trap 'exit' ERR
set -E

# install
export DEBIAN_FRONTEND=noninteractive
apt-get -qy update
apt-get -qy --no-install-recommends --no-install-suggests install \
    gettext-base \
    ssl-cert \
    fcgiwrap \
    geoip-database \
    xml-core \
    nginx-full

mv /tmp/nginx.conf /etc/nginx/nginx.conf
mv /tmp/default /etc/nginx/sites-available/default
mkdir -p /etc/nginx/ssl /etc/nginx/sites-enabled
ln -sf /etc/nginx/sites-available/default /etc/nginx/sites-enabled/default

chown -R www-data:www-data /var/www
ln -sf /dev/stdout /var/log/nginx/access.log
ln -sf /dev/stderr /var/log/nginx/error.log

# set up self-signed SSL certificate for a year
/tmp/generate_sslcert.sh
mv localhost.key /etc/nginx/ssl/
mv localhost.crt /etc/nginx/ssl/
rm -f localhost.csr /tmp/generate_sslcert.sh

# uninstall and clean
apt-get clean -y
rm -r /var/lib/apt/lists/*
rm -rf /usr/share/doc/*
rm -rf /usr/share/doc-gen/*
rm -fr /usr/share/man/*

exit 0

