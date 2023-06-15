#!/bin/bash
# Author: Zhang Huangbin <zhb@iredmail.org>
# Purpose: Some utility functions used by entrypoint scripts.

#
# This file is managed by iRedMail Team <support@iredmail.org> with Ansible,
# please do __NOT__ modify it manually.
#

TIP_FILE='/root/iRedMail/iRedMail.tips'

# System accounts.
SYS_USER_ROOT="root"
SYS_GROUP_ROOT="root"
SYS_USER_SYSLOG="syslog"
SYS_GROUP_SYSLOG="adm"
SYS_USER_NGINX="www-data"
SYS_GROUP_NGINX="www-data"
SYS_USER_VMAIL="vmail"
SYS_GROUP_VMAIL="vmail"
SYS_USER_MYSQL="mysql"
SYS_GROUP_MYSQL="mysql"
SYS_USER_POSTFIX="postfix"
SYS_GROUP_POSTFIX="postfix"
SYS_USER_DOVECOT="dovecot"
SYS_GROUP_DOVECOT="dovecot"
SYS_USER_AMAVISD="amavis"
SYS_GROUP_AMAVISD="amavis"
SYS_USER_CLAMAV="clamav"
SYS_GROUP_CLAMAV="clamav"
SYS_USER_IREDAPD="iredapd"
SYS_GROUP_IREDAPD="iredapd"
SYS_USER_IREDADMIN="iredadmin"
SYS_GROUP_IREDADMIN="iredadmin"
SYS_USER_MLMMJ="mlmmj"
SYS_GROUP_MLMMJ="mlmmj"
SYS_USER_BIND="bind"
SYS_GROUP_BIND="bind"
SYS_USER_MEMCACHED="memcache"
SYS_GROUP_MEMCACHED="memcache"
SYS_USER_NETDATA="netdata"
SYS_GROUP_NETDATA="netdata"
SYS_USER_SOGO="sogo"
SYS_GROUP_SOGO="sogo"

# Commands.
CMD_SED="sed -i -e"
CMD_PERL="perl -pi -e"

# Command used to genrate a random string.
# Usage: password="$(${RANDOM_PASSWORD})"
RANDOM_PASSWORD='eval </dev/urandom tr -dc A-Za-z0-9 | (head -c $1 &>/dev/null || head -c 30)'

#
# System accounts.
#
# Nginx
SYS_USER_NGINX="www-data"
SYS_GROUP_NGINX="www-data"

#
# Nginx
#
NGINX_CONF_DIR_SITES_CONF_DIR="/etc/nginx/sites-conf.d"
NGINX_CONF_DIR_TEMPLATES="/etc/nginx/templates"

LOG_FLAG="[iRedMail]"
LOG() {
    echo -e "\e[32m${LOG_FLAG}\e[0m $@"
}

LOGN() {
    echo -ne "\e[32m${LOG_FLAG}\e[0m $@"
}

LOG_ERROR() {
    echo -e "\e[31m${LOG_FLAG} ERROR:\e[0m $@" >&2
}

LOG_WARNING() {
    echo -e "\e[33m${LOG_FLAG} WARNING:\e[0m $@"
}

check_fqdn_hostname() {
    _host="${1}"

    echo ${_host} | grep '.\..*' &>/dev/null
    if [ X"$?" != X'0' ]; then
        LOG_ERROR "HOSTNAME is not a fully qualified domain name (FQDN)."
        LOG_ERROR "Please fix it in 'iredmail-docker.conf' first."
        exit 255
    fi
}

require_non_empty_var() {
    # Usage: require_non_empty_var <VAR_NAME> <VAR_VALUE>
    _var="$1"
    _value="$2"

    if [[ X"${_value}" == X'' ]]; then
        LOG_ERROR "Variable ${_var} can not be empty, please set it in 'iredmail-docker.conf'."
        exit 255
    fi
}

run_entrypoint() {
    # Usage: run_entrypoint <path-to-entrypoint-script> [arguments]
    _script="$1"
    shift 1
    _opts="$@"

    LOG "[Entrypoint] ${_script} ${_opts}"
    . ${_script} ${_opts}
}

touch_files() {
    # Usage: touch_files <user> <group> <mode> <file> [<file> <file> ...]
    _user="${1}"
    _group="${2}"
    _mode="${3}"
    shift 3
    _files="$@"

    for _f in ${_files}; do
        touch ${_f}
        chown ${_user}:${_group} ${_f}
        chmod ${_mode} ${_f}
    done
}

create_sql_user() {
    # Usage: create_user <user> <password>
    _user="$1"
    _pw="$2"
    _dot_my_cnf="/root/.my.cnf-${_user}"

    cmd_mysql="mysql -u root"

    ${cmd_mysql} mysql -e "SELECT User FROM user WHERE User='${_user}' LIMIT 1" | grep 'User' &>/dev/null
    if [[ X"$?" != X'0' ]]; then
        ${cmd_mysql} -e "CREATE USER '${_user}'@'%';"
    fi

    # Reset password.
    #${cmd_mysql} mysql -e "UPDATE user SET Password=password('${_pw}'),authentication_string=password('${_pw}') WHERE User='${_user}';"
    ${cmd_mysql} mysql -e "ALTER USER '${_user}'@'%' IDENTIFIED BY '${_pw}';"

    cat > ${_dot_my_cnf} <<EOF
[client]
host=${SQL_SERVER_ADDRESS}
port=${SQL_SERVER_PORT}
user="${_user}"
password="${_pw}"
EOF

    chown root ${_dot_my_cnf}
    chmod 0400 ${_dot_my_cnf}
}

create_log_dir() {
    _dir="${1}"
    [[ -d ${_dir} ]] || mkdir -p ${_dir}
    chown ${SYS_USER_SYSLOG}:${SYS_GROUP_SYSLOG} ${_dir}
}

create_log_file() {
    _file="${1}"
    [[ -f ${_file} ]] || touch ${_file}
    chown ${SYS_USER_SYSLOG}:${SYS_GROUP_SYSLOG} ${_file}
}
