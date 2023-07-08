#!/bin/bash

echo "Remove leftover pid files which may cause service fail to start."
find /run -name "*.pid" | xargs rm -f {}

#echo "Waiting for MySQL service..."
#while :; do
#    /usr/bin/mysqladmin ping -h iredmail-mariadb &>/dev/null
#
#    if [[ $? == 0 ]]; then
#        break
#    else
#        sleep 1
#    fi
#done
#echo "MySQL service is up."

CLAMAV_DB_DIR='/var/lib/clamav'
install -d -o clamav -g clamav -m 0775 ${CLAMAV_DB_DIR}
install -d -o clamav -g clamav -m 0755 /run/clamav/

# Has clamav signature database.
_has_sig=NO

# Both bytecode.cvd and main.cvd are required.
if [[ -f ${CLAMAV_DB_DIR}/bytecode.cvd ]] && [[ -f ${CLAMAV_DB_DIR}/main.cvd ]]; then
    # Either daily.cvd or daily.cld is required.
    if [[ -f ${CLAMAV_DB_DIR}/daily.cvd ]] || [[ -f ${CLAMAV_DB_DIR}/daily.cld ]]; then
        _has_sig=YES
    fi
fi

if [[ "${_has_sig}" == 'NO' ]]; then
    echo "* No ClamAV signature database found, running freshclam..."
    freshclam --verbose --user=clamav --datadir=/var/lib/clamav
fi

# Deploy all components.
time /gosible -e /settings.json -p docker.yml -d

install -d -o www-data -g www-data -m 0755 /run/php

echo "* Run freshclam in background."
freshclam --checks=1 --daemon --user=clamav --config-file=/etc/clamav/freshclam.conf

# Run specified commands in Dockerfile `CMD`.
echo "CMD: $@"
exec "$@"
