__WARNING__: THIS IS A ALPHA EDITION, DO NOT TRY IT IN PRODUCTION YET.

- Base image is Ubuntu 22.04 (jammy).
- Dockerized iRedMail follows the [Best Practice of iRedMail Easy platform](https://docs.iredmail.org/iredmail-easy.best.practice.html).

# Getting Started

> In below sample setup:
>
> - Server hostname: `mail.a.io`
> - First email domain name: `a.io`
> - Domain admin: `postmaster@a.io`
> - Domain admin password: `123456`
> - MySQL root password: `123456`

Create directory `/iredmail` as working directory:

```
mkdir /iredmail
cd /iredmail
```

Save this content as `/iredmail/settings.json` (Note: this file should be
generated on a web UI in the future):

```
{
    "iredmail_backend": "mariadb",
    "storage_base_dir": "/var/vmail",
    "first_mail_domain": "a.io",
    "first_domain_admin_password": "123456",
    "inventory_hostname": "mail.a.io",
    "sql_server_address": "iredmail-mariadb",
    "mysql_server_address": "iredmail-mariadb",
    "mysql_grant_host": "ALL",
    "mysql_root_password": "123456",
    "use_antispam": true,
    "use_nginx": true,
    "use_phpfpm": true,
    "use_roundcube": true,
    "use_autoconfig": true,
    "use_iredapd": true,
    "use_sogo": true,
    "use_fail2ban": true,
    "use_iredadmin": true,
    "use_netdata": true,
    "use_adminer": true,
    "use_prosody": true,
    "use_backup": true,
    "homepage_application": "roundcube",
    "ovecot_enable_last_login": true,
    "dovecot_enable_fts": true,
    "sogo_prefork_processes": 5,
    "fail2ban_store_banned_ip_in_db": true
}
```

Save this content as `/iredmail/docker-compose.yml` (Note: this file should be
generated on a web UI in the future):

```
version: "3"
services:
  iredmail-mariadb:
    image: mariadb:11.0-jammy
    environment:
      - MARIADB_ROOT_PASSWORD=123456
    volumes:
      - ./data/mysql:/var/lib/mysql  
    networks:
      iredmail-network:
        aliases:
          - iredmail-mariadb

  iredmail:
    image: iredmail/test-mariadb:nightly
    container_name: iredmail
    restart: unless-stopped
    depends_on:
      - iredmail-mariadb
    volumes:
      - ./settings.json:/settings.json
      - ./data/dot_iredmail:/root/.iredmail
      - ./data/backup_mysql:/var/vmail/backup/mysql
      - ./data/mailboxes:/var/vmail/vmail1
      - ./data/mlmmj:/var/vmail/mlmmj
      - ./data/mlmmj_archive:/var/vmail/mlmmj-archive
      - ./data/imapsieve_copy:/var/vmail/imapsieve_copy
      - ./data/custom:/opt/iredmail/custom
      - ./data/ssl:/opt/iredmail/ssl
      - ./data/clamav:/var/lib/clamav
      - ./data/sa_rules:/var/lib/spamassassin
      - ./data/postfix_queue:/var/spool/postfix
    ports:
      - 80:80
      - 443:443
      - 110:110
      - 995:995
      - 143:143
      - 993:993
      - 25:25
      - 465:465
      - 587:587
    networks:
      iredmail-network:  

networks:
  iredmail-network:
    driver: bridge
```

Run:

```
docker-compose up
```

Notes:

- On first run, it will generate a self-signed ssl cert, this may take a long
  time, please be patient.
- Do not forget to [setup DNS records](https://docs.iredmail.org/setup.dns.html)
  for your server hostname and email domain names.
- Docker on Windows and macOS might be buggy, please run it on Linux host instead.

# Hardware requirements

- At least 4GB RAM is required for a low traffic production mail server.

# Installed softwares

- Postfix: SMTP server.
- Dovecot: POP3/IMAP/LMTP/Sieve server, also offers SASL AUTH service for Postfix.
- mlmmj: mailing list manager.
- mlmmjadmin: RESTful API server used to manage (mlmmj) mailing lists.
- Amavisd-new + ClamAV + SpamAssassin: anti-spam and anti-virus, DKIM signing and verification, etc.
- iRedAPD: Postfix policy server. Developed by iRedMail team.
- Fail2ban: scans log files and bans bad clients.
- Roundcube: webmail.
- iRedAdmin: web-based admin panel, open source edition.
- SOGo Groupware

You may want to check [this tutorial](https://docs.iredmail.org/network.ports.html)
to figure out the mapping of softwares and network ports.

# Exposed network ports

- 80: HTTP
- 443: HTTPS
- 25: SMTP
- 465: SMTPS (SMTP over SSL)
- 587: SUBMISSION (SMTP over TLS)
- 143: IMAP over TLS
- 993: IMAP over SSL
- 110: POP3 over TLS
- 995: POP3 over SSL
- 4190: Managesieve service
