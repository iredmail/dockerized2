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

# Deploy all components.
time /gosible -e /settings.json -p docker.yml

# Run specified commands in Dockerfile `CMD`.
echo "CMD: $@"
exec "$@"
