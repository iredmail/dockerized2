#!/bin/bash

# Remove leftover pid files which may cause service fail to start.
find /run -name "*.pid" | xargs rm -f {}

# System accounts.
export SYS_USER_SYSLOG="syslog"
export SYS_GROUP_SYSLOG="adm"
export SYS_USER_NGINX="www-data"
export SYS_GROUP_NGINX="www-data"
export SYS_USER_CLAMAV="clamav"
export SYS_GROUP_CLAMAV="clamav"

install -d -m 0755 /var/run/supervisord /var/log/supervisor
install -d -o ${SYS_USER_SYSLOG} -g ${SYS_GROUP_SYSLOG} -m 0755 /var/log/php-fpm
install -d -o ${SYS_USER_NGINX}  -g ${SYS_GROUP_NGINX}  -m 0755 /run/php
install -d -o ${SYS_USER_CLAMAV} -g ${SYS_GROUP_CLAMAV} -m 0755 /run/clamav/

# Deploy all components.
time /gosible -e /settings.json -p docker.yml

# Run specified commands in Dockerfile `CMD`.
echo "CMD: $@"
exec "$@"