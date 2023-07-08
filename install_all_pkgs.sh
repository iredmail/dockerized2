#!/bin/bash
# Author: Zhang Huangbin <zhb@iredmail.org>

export DEBIAN_FRONTEND='noninteractive'

export IREDAPD_VERSION='5.3.3'
export IREDADMIN_VERSION='2.3'
export MLMMJADMIN_VERSION='3.1.7'
export ROUNDCUBE_VERSION='1.6.2'

export PKGS_MARIADB="altermime amavisd-new apt-transport-https arj aspell bind9-dnsutils bzip2 ca-certificates cabextract clamav-daemon clamav-freshclam cpio cron curl dbus dirmngr dovecot-fts-xapian dovecot-imapd dovecot-lmtpd dovecot-managesieved dovecot-mysql dovecot-pop3d dovecot-sieve fail2ban gpg-agent gzip iptables less libcrypt-openssl-rsa-perl libdbd-mysql-perl liblz4-tool libmail-dkim-perl libmail-spf-perl libsasl2-modules lzop mailutils mariadb-client mariadb-server mcrypt mlmmj nginx nomarch openssl p7zip-full pax php-bz2 php-cli php-curl php-fpm php-gd php-imap php-intl php-json php-ldap php-mbstring php-mysql php-pgsql php-pspell php-xml php-zip postfix postfix-mysql postfix-pcre python3-apt python3-bcrypt python3-dnspython python3-jinja2 python3-ldap python3-more-itertools python3-netifaces python3-psycopg2 python3-pymysql python3-requests python3-setuptools python3-simplejson python3-sqlalchemy rpm rsyslog software-properties-common spamassassin supervisor unrar-free unzip uwsgi uwsgi-plugin-python3 wget"
export PKGS_PGSQL="altermime amavisd-new apt-transport-https arj aspell bind9-dnsutils bzip2 ca-certificates cabextract clamav-daemon clamav-freshclam cpio cron curl dbus dirmngr dovecot-fts-xapian dovecot-imapd dovecot-lmtpd dovecot-managesieved dovecot-pgsql dovecot-pop3d dovecot-sieve fail2ban gpg-agent gzip iptables less libcrypt-openssl-rsa-perl libdbd-mysql-perl liblz4-tool libmail-dkim-perl libmail-spf-perl libsasl2-modules lzop mailutils mariadb-client mariadb-server mcrypt mlmmj nginx nomarch openssl p7zip-full pax php-bz2 php-cli php-curl php-fpm php-gd php-imap php-intl php-json php-ldap php-mbstring php-mysql php-pgsql php-pspell php-xml php-zip postfix postfix-pcre postfix-pgsql python3-apt python3-bcrypt python3-dnspython python3-jinja2 python3-ldap python3-more-itertools python3-netifaces python3-psycopg2 python3-pymysql python3-requests python3-setuptools python3-simplejson python3-sqlalchemy rpm rsyslog software-properties-common spamassassin supervisor unrar-free unzip uwsgi uwsgi-plugin-python3 wget postgresql-client"
PKGS_OPENLDAP="altermime amavisd-new apt-transport-https arj aspell bind9-dnsutils bzip2 ca-certificates cabextract clamav-daemon clamav-freshclam cpio cron curl dbus dirmngr dovecot-fts-xapian dovecot-imapd dovecot-ldap dovecot-lmtpd dovecot-managesieved dovecot-mysql dovecot-pop3d dovecot-sieve fail2ban gpg-agent gzip iptables less libcrypt-openssl-rsa-perl libdbd-mysql-perl liblz4-tool libmail-dkim-perl libmail-spf-perl libsasl2-modules lzop mailutils mariadb-client mariadb-server mcrypt mlmmj nginx nomarch openssl p7zip-full pax php-bz2 php-cli php-curl php-fpm php-gd php-imap php-intl php-json php-ldap php-mbstring php-mysql php-pgsql php-pspell php-xml php-zip postfix postfix-ldap postfix-mysql postfix-pcre python3-apt python3-bcrypt python3-dnspython python3-jinja2 python3-ldap python3-more-itertools python3-netifaces python3-psycopg2 python3-pymysql python3-requests python3-setuptools python3-simplejson python3-sqlalchemy rpm rsyslog software-properties-common spamassassin supervisor unrar-free unzip uwsgi uwsgi-plugin-python3 wget"

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

echo "Install all packages."
apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends ${PKGS_MARIADB} ${PKGS_PGSQL} ${PKGS_OPENLDAP}

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
