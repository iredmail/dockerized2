#!/bin/sh

groupadd --gid 115 postgres
useradd \
    --uid 115 \
    --gid postgres \
    --shell /sbin/nologin \
    postgres

groupadd --gid 2000 vmail
useradd \
    --uid 2000 \
    --gid vmail \
    --shell /sbin/nologin \
    vmail

groupadd --gid 2003 mlmmj
useradd \
    --uid 2003 \
    --gid mlmmj \
    --shell /sbin/nologin \
    mlmmj

groupadd --gid 2002 iredapd
useradd \
    --uid 2002 \
    --gid iredapd \
    --shell /sbin/nologin \
    iredapd

groupadd --gid 2001 iredadmin
useradd \
    --uid 2001 \
    --gid iredadmin \
    --shell /sbin/nologin \
    iredadmin

groupadd --gid 2001 bind
useradd \
    --uid 2001 \
    --gid bind \
    --shell /sbin/nologin \
    bind

groupadd --gid 2004 netdata
useradd \
    --uid 2004 \
    --gid netdata \
    --shell /sbin/nologin \
    netdata    