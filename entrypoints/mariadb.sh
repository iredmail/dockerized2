#!/bin/bash
# Author: Zhang Huangbin <zhb@iredmail.org>

SYS_USER_MYSQL="mysql"
SYS_GROUP_MYSQL="mysql"

DATA_DIR="/var/lib/mysql"
CUSTOM_CONF_DIR="/opt/iredmail/custom/mysql"
SOCKET_PATH="/run/mysqld/mysqld.sock"
DOT_MY_CNF="/root/.my.cnf"

# Add required directories.
if [[ ! -d ${CUSTOM_CONF_DIR} ]]; then
    #echo "Create directory used to store custom config files: ${CUSTOM_CONF_DIR}".
    mkdir -p ${CUSTOM_CONF_DIR}
fi

# Create data directory if not present
[[ -d ${DATA_DIR} ]] || mkdir -p ${DATA_DIR}

_first_run="NO"

if [[ ! -d "${DATA_DIR}/mysql" ]]; then
    _first_run="YES"
fi

cmd_mysql_opts="--protocol=socket -uroot -hlocalhost --socket=${SOCKET_PATH}"
cmd_mysql="mysql ${cmd_mysql_opts}"
cmd_mysql_with_dot_cnf="mysql --defaults-file=${DOT_MY_CNF} ${cmd_mysql_opts}"

cmd_mysqld_opts="--user=root --bind-address=127.0.0.1 --datadir=${DATA_DIR} --socket=${SOCKET_PATH}"
if [[ X"${_first_run}" != X'YES' ]]; then
    # '--skip-grant-tables' doesn't work at first run.
    cmd_mysqld_opts="${cmd_mysqld_opts} --skip-grant-tables"
fi

start_temp_mysql_instance() {
    echo "Starting temporary MariaDB instance."
    mysqld ${cmd_mysqld_opts} &
    _pid="$!"
    echo "${_pid}" > /tmp/temp_instance_pid

    # Wait until MariaDB instance is started
    #echo "Waiting for MariaDB service ..."
    for i in $(seq 30); do
        if mysqladmin --socket="${SOCKET_PATH}" ping &>/dev/null; then
            break
        fi

        sleep 1

        if [[ "$i" == 30 ]]; then
            echo "Initialization failed. Please check ${DATA_DIR}/mysqld.err for more details."
            exit 255
        fi
    done
}

stop_temp_mysql_instance() {
    echo "Stopping the temporary mysql instance."
    _pid="$(cat /tmp/temp_instance_pid)"

    if ! kill -s TERM "${_pid}" || ! wait "${_pid}"; then
        echo "Failed to stop temporary MariaDB instance."
        exit 255
    fi

    rm -f /tmp/temp_instance_pid
    echo "Stopped the temporary mysql instance."
}

create_root_user() {
    _file="$(mktemp -u)"
    _grant_host='%'

    cat <<-EOF > ${_file}
-- What's done in this file shouldn't be replicated
-- or products like mysql-fabric won't work
SET @@SESSION.SQL_LOG_BIN=0;
SET PASSWORD FOR 'root'@'localhost'=PASSWORD('${MYSQL_ROOT_PASSWORD}');
GRANT ALL ON *.* TO 'root'@'localhost' WITH GRANT OPTION;

CREATE USER 'root'@'${_grant_host}' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
GRANT ALL ON *.* TO 'root'@'${_grant_host}' WITH GRANT OPTION;

DELETE from mysql.user WHERE User='';
DROP DATABASE IF EXISTS test;
FLUSH PRIVILEGES;
EOF

    if [[ -f ${DOT_MY_CNF} ]]; then
        _cmd_mysql="${cmd_mysql_with_dot_cnf}"
    else
        _cmd_mysql="${cmd_mysql}"
    fi

    echo "Create MariaDB root user."
    sh -c "${_cmd_mysql} < ${_file}"
    rm -f ${_file}
}

#reset_password() {
#    _user="$1"
#    _host="$2"
#    _pw="$3"
#
#    echo "Reset password for SQL user '${_user}'%'${_host}'."
#    mysql -u root --socket=${SOCKET_PATH} <<EOF
#FLUSH PRIVILEGES;
#ALTER USER '${_user}'@'${_host}' IDENTIFIED BY '${_pw}';
#FLUSH PRIVILEGES;
#EOF
#}

# Create directory used to store socket/pid files.
install -d -o ${SYS_USER_MYSQL} -g ${SYS_GROUP_MYSQL} -m 0755 $(dirname ${SOCKET_PATH})

# Initialize database
if [[ X"${_first_run}" == X'YES' ]]; then
    echo "Initializing database ..."
    mysql_install_db --user=${SYS_USER_MYSQL} --datadir=${DATA_DIR} >/dev/null
fi

# Start service since we always reset root password.
start_temp_mysql_instance

# Generate all config files with custom settings.
/gosible -e /root/.iredmail/settings.json -p docker.yml

stop_temp_mysql_instance
