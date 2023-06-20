#!/bin/bash
# Author: Zhang Huangbin <zhb@iredmail.org>

export DEBIAN_FRONTEND='noninteractive'

export IREDAPD_VERSION='5.3.2'
export IREDADMIN_VERSION='2.3'
export MLMMJADMIN_VERSION='3.1.7'
export ROUNDCUBE_VERSION='1.6.1'

# Required binary packages.
PKGS_BASE="apt-transport-https bzip2 cron ca-certificates curl dbus dirmngr gzip openssl python3-apt python3-setuptools rsyslog software-properties-common unzip python3-pymysql python3-psycopg2"
PKGS_NGINX="nginx"
PKGS_PHP_FPM="php-fpm php-cli"
PKGS_POSTFIX="postfix postfix-pcre libsasl2-modules postfix-mysql"
PKGS_DOVECOT="dovecot-imapd dovecot-pop3d dovecot-lmtpd dovecot-managesieved dovecot-sieve dovecot-mysql dovecot-fts-xapian"
PKGS_AMAVISD="amavisd-new libcrypt-openssl-rsa-perl libmail-dkim-perl altermime arj nomarch cpio liblz4-tool lzop cabextract p7zip-full rpm libmail-spf-perl unrar-free pax libdbd-mysql-perl"
PKGS_SPAMASSASSIN="spamassassin"
PKGS_CLAMAV="clamav-freshclam clamav-daemon"
PKGS_IREDAPD="python3-sqlalchemy python3-dnspython python3-pymysql python3-ldap python3-psycopg2 python3-more-itertools python3-wheel python3-pip"
PKGS_IREDADMIN="python3-jinja2 python3-netifaces python3-bcrypt python3-dnspython python3-simplejson python3-more-itertools"
PKGS_MLMMJ="mlmmj altermime"
PKGS_MLMMJADMIN="uwsgi uwsgi-plugin-python3 python3-requests python3-pymysql python3-psycopg2 python3-ldap python3-more-itertools"
PKGS_FAIL2BAN="fail2ban bind9-dnsutils iptables"
PKGS_ROUNDCUBE="php-bz2 php-curl php-gd php-imap php-intl php-json php-ldap php-mbstring php-mysql php-pgsql php-pspell php-xml php-zip mcrypt mariadb-client aspell"
PKGS_BIND="bind9 bind9utils dnsutils"
PKGS_SOGO="memcached sogo sogo-activesync sogo-common libsope-appserver4.9 libsope-core4.9 libsope-gdl1-4.9 libsope-ldap4.9 libsope-mime4.9 libsope-xml4.9 sope4.9-libxmlsaxdriver"
PKGS_ALL="wget gpg-agent supervisor mailutils less vim-tiny
    ${PKGS_BASE}
    ${PKGS_NGINX}
    ${PKGS_PHP_FPM}
    ${PKGS_POSTFIX}
    ${PKGS_DOVECOT}
    ${PKGS_AMAVISD}
    ${PKGS_SPAMASSASSIN}
    ${PKGS_CLAMAV}
    ${PKGS_IREDAPD}
    ${PKGS_IREDADMIN}
    ${PKGS_MLMMJ}
    ${PKGS_MLMMJADMIN}
    ${PKGS_FAIL2BAN}
    ${PKGS_ROUNDCUBE}
    ${PKGS_BIND}
    ${PKGS_SOGO}"

# Required directories.
export WEB_APP_ROOTDIR="/opt/www"

# Upgrade all packages.
apt-get update && apt-get upgrade -y

echo "Install base packages."
apt-get install -y apt-utils rsyslog wget gnupg2

echo "Add apt repo for SOGo Groupware."
echo "deb https://packages.sogo.nu/nightly/5/ubuntu jammy jammy" > /etc/apt/sources.list.d/sogo-nightly.list
wget -q \
    -O /tmp/sogo-nightly \
    "https://keys.openpgp.org/vks/v1/by-fingerprint/74FFC6D72B925A34B5D356BDF8A27B36A6E2EAE9" >/dev/null && \
    gpg --dearmor /tmp/sogo-nightly
    mv /tmp/sogo-nightly.gpg /etc/apt/trusted.gpg.d/
    rm -f /tmp/sogo-nightly

echo "Install packages: ${PKGS_ALL}"
apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends ${PKGS_ALL}
apt-get clean && apt-get autoclean && rm -rf /var/lib/apt/lists/*

# Create required directories.
mkdir -p ${WEB_APP_ROOTDIR}

# Install iRedAPD.
wget -c -q https://github.com/iredmail/iRedAPD/archive/${IREDAPD_VERSION}.tar.gz && \
    tar xzf ${IREDAPD_VERSION}.tar.gz -C /opt && \
    rm -f ${IREDAPD_VERSION}.tar.gz && \
    ln -s /opt/iRedAPD-${IREDAPD_VERSION} /opt/iredapd && \
    chown -R iredapd:iredapd /opt/iRedAPD-${IREDAPD_VERSION} && \
    chmod -R 0500 /opt/iRedAPD-${IREDAPD_VERSION} && \

# Install mlmmjadmin.
wget -c -q https://github.com/iredmail/mlmmjadmin/archive/${MLMMJADMIN_VERSION}.tar.gz && \
    tar zxf ${MLMMJADMIN_VERSION}.tar.gz -C /opt && \
    rm -f ${MLMMJADMIN_VERSION}.tar.gz && \
    ln -s /opt/mlmmjadmin-${MLMMJADMIN_VERSION} /opt/mlmmjadmin && \
    cd /opt/mlmmjadmin-${MLMMJADMIN_VERSION} && \
    chown -R mlmmj:mlmmj /opt/mlmmjadmin-${MLMMJADMIN_VERSION} && \
    chmod -R 0500 /opt/mlmmjadmin-${MLMMJADMIN_VERSION}

# Install Roundcube.
wget -c -q https://github.com/roundcube/roundcubemail/releases/download/${ROUNDCUBE_VERSION}/roundcubemail-${ROUNDCUBE_VERSION}-complete.tar.gz && \
    tar zxf roundcubemail-${ROUNDCUBE_VERSION}-complete.tar.gz -C /opt/www && \
    rm -f roundcubemail-${ROUNDCUBE_VERSION}-complete.tar.gz && \
    ln -s /opt/www/roundcubemail-${ROUNDCUBE_VERSION} /opt/www/roundcubemail && \
    chown -R root:root /opt/www/roundcubemail-${ROUNDCUBE_VERSION} && \
    chmod -R 0755 /opt/www/roundcubemail-${ROUNDCUBE_VERSION} && \
    cd /opt/www/roundcubemail-${ROUNDCUBE_VERSION} && \
    chown -R www-data:www-data temp logs && \
    chmod 0000 CHANGELOG.md INSTALL LICENSE README* UPGRADING installer SQL

 # Install iRedAdmin (open source edition).
wget -c -q https://github.com/iredmail/iRedAdmin/archive/${IREDADMIN_VERSION}.tar.gz && \
    tar xzf ${IREDADMIN_VERSION}.tar.gz -C /opt/www && \
    rm -f ${IREDADMIN_VERSION}.tar.gz && \
    ln -s /opt/www/iRedAdmin-${IREDADMIN_VERSION} /opt/www/iredadmin && \
    chown -R iredadmin:iredadmin /opt/www/iRedAdmin-${IREDADMIN_VERSION} && \
    chmod -R 0555 /opt/www/iRedAdmin-${IREDADMIN_VERSION}
