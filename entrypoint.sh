#!/bin/bash

echo "Waiting for MySQL service..."
while :; do
    /usr/bin/mysqladmin ping -h iredmail-mariadb &>/dev/null

    if [[ $? == 0 ]]; then
        break
    else
        sleep 1
    fi
done
echo "MySQL service is up."

install -d -o www-data -g www-data -m 0755 /run/php
install -d -o clamav   -g clamav   -m 0755 /run/clamav/
install -d -o syslog   -g adm      -m 0755 /var/log/php-fpm
install -d -o root     -g root     -m 0755 /var/run/supervisord /var/log/supervisor

# Deploy all components.
time /gosible -e /settings.json -p docker.yml

# Run specified commands in Dockerfile `CMD`.
echo "CMD: $@"
exec "$@"
