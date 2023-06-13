#!/bin/bash
# Author: Zhang Huangbin <zhb@iredmail.org>

#
# This file is managed by iRedMail Team <support@iredmail.org> with Ansible,
# please do __NOT__ modify it manually.
#

ENTRYPOINTS_DIR="/docker/entrypoints"
SETTINGS_CONF="${ENTRYPOINTS_DIR}/settings.conf"

. ${ENTRYPOINTS_DIR}/functions.sh

# Store env in a temporary file for further reading.
tmp_env_file='/tmp/env'
env > ${tmp_env_file}

. ${SETTINGS_CONF}

params="$(grep '^[0-9a-zA-Z]' ${SETTINGS_CONF} | awk -F'=' '{print $1}')"

# For gosible.
mkdir -p /root/.iredmail/kv/

# Set random passwords.
for param in ${params}; do
    if echo ${param} | grep -E '(_DB_PASSWORD|^MLMMJADMIN_API_TOKEN|^IREDAPD_SRS_SECRET|^ROUNDCUBE_DES_KEY|^MYSQL_ROOT_PASSWORD|^VMAIL_DB_ADMIN_PASSWORD|^SOGO_SIEVE_MASTER_PASSWORD|^FIRST_MAIL_DOMAIN_ADMIN_PASSWORD)$' &>/dev/null; then
        pw="$(${RANDOM_PASSWORD})"

        if grep "^${param}=" ${SETTINGS_CONF} &>/dev/null; then
            # Replace existing variable to avoid duplicate lines.
            ${CMD_SED} "s#^\(${param}=\).*#\1${pw}#g" ${SETTINGS_CONF}
        else
            echo "${param}=${pw}" >> ${SETTINGS_CONF}
        fi
    fi
done

# If parameter is defined as environment variables, replace it in config file.
for param in ${params}; do
    _env_line="$(grep "^${param}=" ${tmp_env_file})"
    _env_value="${_env_line#*=}"

    if [ X"${_env_value}" != X'' ]; then
        # Replace in place instead of appending it.
        ${CMD_SED} "s#^${param}=.*#${param}=${_env_value}#g" ${SETTINGS_CONF}
    fi
done
rm -f ${tmp_env_file}

# It now contains both default and custom settings.
. ${SETTINGS_CONF}

# Make sure config file is not world-readable.
chown root ${SETTINGS_CONF}
chmod 0400 ${SETTINGS_CONF}

# Write to /root/.iredmail/kv/
set -x
params="$(grep '^[0-9a-zA-Z]' ${SETTINGS_CONF} | awk -F'=' '{print $1}')"
for param in ${params}; do
    if echo ${param} | grep -E '(_DB_PASSWORD|^MLMMJADMIN_API_TOKEN|^IREDAPD_SRS_SECRET|^ROUNDCUBE_DES_KEY|^MYSQL_ROOT_PASSWORD|^VMAIL_DB_ADMIN_PASSWORD|^SOGO_SIEVE_MASTER_PASSWORD|^FIRST_MAIL_DOMAIN_ADMIN_PASSWORD)$' &>/dev/null; then
        line=$(grep -E "^${param}=" ${SETTINGS_CONF})
        v="$(echo ${line#*=})"

        if echo ${param} | grep -E '_DB_PASSWORD$' &>/dev/null; then
            u="$(echo ${param%_DB_PASSWORD} | tr [A-Z] [a-z])"
            echo "${v}" > /root/.iredmail/kv/sql_user_${u}
            unset u
        elif [[ X"${param}" == X'MYSQL_ROOT_PASSWORD' ]]; then
            echo "${v}" > /root/.iredmail/kv/sql_user_root
        elif [[ X"${param}" == X'VMAIL_DB_ADMIN_PASSWORD' ]]; then
            echo "${v}" > /root/.iredmail/kv/sql_user_vmailadmin
        elif [[ X"${param}" == X'FIRST_MAIL_DOMAIN_ADMIN_PASSWORD' ]]; then
            echo "${v}" > /root/.iredmail/kv/first_mail_domain_admin_password
        elif [[ X"${param}" == "SOGO_SIEVE_MASTER_PASSWORD" ]]; then
            echo "${v}" > /root/.iredmail/kv/sogo_sieve_master_password
        elif echo ${param} | grep -E '^(MLMMJADMIN_API_TOKEN|IREDAPD_SRS_SECRET|ROUNDCUBE_DES_KEY)$' &>/dev/null; then
            name="$(echo ${param} | tr [A-Z] [a-z])"
            echo "${v}" > /root/.iredmail/kv/${name}
            unset name
        fi
    fi
done
set +x

# Check required variables.
require_non_empty_var HOSTNAME ${HOSTNAME}
check_fqdn_hostname ${HOSTNAME}
require_non_empty_var FIRST_MAIL_DOMAIN ${FIRST_MAIL_DOMAIN}
require_non_empty_var FIRST_MAIL_DOMAIN_ADMIN_PASSWORD ${FIRST_MAIL_DOMAIN_ADMIN_PASSWORD}

install -d -m 0755 /var/run/supervisord /var/log/supervisor

LOG "Remove leftover pid files which may cause service fail to start."
find /run -name "*.pid" | xargs rm -f {}

# Store FQDN in /etc/mailname.
# FYI: https://wiki.debian.org/EtcMailName
echo "${HOSTNAME}" > /etc/mailname

run_entrypoint ${ENTRYPOINTS_DIR}/rsyslog.sh
run_entrypoint ${ENTRYPOINTS_DIR}/cron.sh
run_entrypoint ${ENTRYPOINTS_DIR}/mariadb.sh
run_entrypoint ${ENTRYPOINTS_DIR}/dovecot.sh
run_entrypoint ${ENTRYPOINTS_DIR}/postfix.sh
run_entrypoint ${ENTRYPOINTS_DIR}/mlmmj.sh
run_entrypoint ${ENTRYPOINTS_DIR}/mlmmjadmin.sh

# Update all placeholders in /root/iRedMail/iRedMail.tips.
. ${ENTRYPOINTS_DIR}/tip_file.sh

# Applications controlled by supervisor.
# Program name must be the name of modular config files without '.conf'.
SUP_SERVICES="cron rsyslog mariadb dovecot postfix mlmmjadmin"

if [[ X"${USE_IREDAPD}" == X'YES' ]]; then
    run_entrypoint ${ENTRYPOINTS_DIR}/iredapd.sh
    SUP_SERVICES="${SUP_SERVICES} iredapd"
fi

if [[ X"${USE_ANTISPAM}" == X'YES' ]]; then
    run_entrypoint ${ENTRYPOINTS_DIR}/clamav.sh
    run_entrypoint ${ENTRYPOINTS_DIR}/antispam.sh
    SUP_SERVICES="${SUP_SERVICES} clamav amavisd"
fi

# Nginx & php-fpm
if [[ X"${USE_ROUNDCUBE}" == X'YES' ]]; then
    run_entrypoint ${ENTRYPOINTS_DIR}/nginx.sh
    run_entrypoint ${ENTRYPOINTS_DIR}/phpfpm.sh
fi

if [[ X"${USE_ROUNDCUBE}" == X'YES' ]]; then
    run_entrypoint ${ENTRYPOINTS_DIR}/roundcube.sh
    SUP_SERVICES="${SUP_SERVICES} nginx phpfpm"
fi

if [[ X"${USE_FAIL2BAN}" == X'YES' ]]; then
    run_entrypoint ${ENTRYPOINTS_DIR}/fail2ban.sh
    SUP_SERVICES="${SUP_SERVICES} fail2ban"
fi

if [[ X"${USE_IREDADMIN}" == X'YES' ]]; then
    run_entrypoint ${ENTRYPOINTS_DIR}/iredadmin.sh
    SUP_SERVICES="${SUP_SERVICES} iredadmin"
fi

for srv in ${SUP_SERVICES}; do
    ln -sf /etc/supervisor/conf-available/${srv}.conf /etc/supervisor/conf.d/${srv}.conf
done

# Run specified commands in Dockerfile `CMD`.
LOG "CMD: $@"
exec "$@"
