#!/bin/bash
# Author: Zhang Huangbin <zhb@iredmail.org>

. /docker/entrypoints/functions.sh

POSTFIX_SPOOL_DIR="/var/spool/postfix"
POSTFIX_CUSTOM_DISCLAIMER_DIR="/opt/iredmail/custom/postfix/disclaimer"

POSTFIX_LOG_FILE="/var/log/mail.log"

SSL_DHPARAM512_FILE='/opt/iredmail/ssl/dhparam512.pem'
SSL_DHPARAM2048_FILE='/opt/iredmail/ssl/dhparam2048.pem'

# Create default disclaimer files.
touch ${POSTFIX_CUSTOM_DISCLAIMER_DIR}/default.txt
touch ${POSTFIX_CUSTOM_DISCLAIMER_DIR}/default.html

install -d -o ${SYS_USER_ROOT} -g ${SYS_GROUP_POSTFIX} -m 0770 ${POSTFIX_SPOOL_DIR}/etc
for f in localtime hosts resolv.conf; do
    if [[ -f /etc/${f} ]]; then
        cp -f /etc/${f} ${POSTFIX_SPOOL_DIR}/etc/
        chown ${SYS_USER_POSTFIX}:${SYS_GROUP_ROOT} ${POSTFIX_SPOOL_DIR}/etc/${f}
        chmod 0755 ${POSTFIX_SPOOL_DIR}/etc/${f}
    fi
done

if [[ ! -f ${SSL_DHPARAM512_FILE} ]]; then
    openssl dhparam -out ${SSL_DHPARAM512_FILE} 512 >/dev/null
fi
if [[ ! -f ${SSL_DHPARAM2048_FILE} ]]; then
    LOG "Generating dh param file: ${SSL_SSL_DHPARAM2048_FILE}. It make take a long time."
    openssl dhparam -out ${SSL_DHPARAM2048_FILE} 2048 >/dev/null
fi
chmod 0644 ${SSL_DHPARAM512_FILE} ${SSL_DHPARAM2048_FILE}

# Make sure log file exists.
create_log_file ${POSTFIX_LOG_FILE}

if [ X"${POSTFIX_LOG_FILE}" != X'/var/log/maillog' ]; then
    # Create symbol link of mail log file.
    ln -sf ${POSTFIX_LOG_FILE} /var/log/maillog
fi

# Don't log to multiple files.
${CMD_PERL} 's/^(.*mail\.info)/#$1/g' /etc/rsyslog.d/50-default.conf
${CMD_PERL} 's/^(.*mail\.warn)/#$1/g' /etc/rsyslog.d/50-default.conf
${CMD_PERL} 's/^(.*mail\.err)/#$1/g' /etc/rsyslog.d/50-default.conf
