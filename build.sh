#!/usr/bin/env bash

label="iredmail/test-mariadb"

docker build \
    --progress plain \
    -f Dockerfile-amd64 \
    --tag ${label}:nightly .
