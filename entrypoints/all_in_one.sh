#!/bin/bash

# Remove leftover pid files which may cause service fail to start.
find /run -name "*.pid" | xargs rm -f {}

. /docker/entrypoints/functions.sh

run_entrypoint ${ENTRYPOINTS_DIR}/mariadb.sh
#run_entrypoint ${ENTRYPOINTS_DIR}/rsyslog.sh
#run_entrypoint ${ENTRYPOINTS_DIR}/cron.sh

install -d -m 0755 /var/run/supervisord /var/log/supervisor
install -d -o ${SYS_USER_SYSLOG} -g ${SYS_GROUP_SYSLOG} -m 0755 /var/log/php-fpm
install -d -o ${SYS_USER_NGINX}  -g ${SYS_GROUP_NGINX}  -m 0755 /run/php
install -d -o ${SYS_USER_CLAMAV} -g ${SYS_GROUP_CLAMAV} -m 0755 /run/clamav/

SUP_SERVICES="cron rsyslog mariadb dovecot postfix mlmmjadmin iredapd clamav amavisd nginx phpfpm fail2ban iredadmin"
for srv in ${SUP_SERVICES}; do
    ln -sf /etc/supervisor/conf-available/${srv}.conf /etc/supervisor/conf.d/${srv}.conf
done

# Run specified commands in Dockerfile `CMD`.
LOG "CMD: $@"
exec "$@"
