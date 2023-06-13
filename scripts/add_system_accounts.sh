#!/bin/sh

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
