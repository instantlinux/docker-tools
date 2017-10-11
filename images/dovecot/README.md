## dovecot
[![](https://images.microbadger.com/badges/version/instantlinux/dovecot.svg)](https://microbadger.com/images/instantlinux/dovecot "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/dovecot.svg)](https://microbadger.com/images/instantlinux/dovecot "Image badge") [![](https://images.microbadger.com/badges/commit/instantlinux/dovecot.svg)](https://microbadger.com/images/instantlinux/dovecot "Commit badge")

The dovecot imapd daemon in a small Alpine Linux container, with
postfix for local delivery and procmail for filtering.

### Usage

Configuration is defined as files in a volume mounted as
/etc/dovecot/conf.local. Within that directory:

* Define your local settings as dovecot.conf.

* If you have an LDAP server, put its settings in dovecot-ldap.conf.

Also configure postfix as described in the postfix image.

See etc-example directory and docker-compose.yml.

### Variables

| Variable | Default | Description |
| -------- | ------- | ----------- |
| LDAP_PASSWD_SECRET | ldap-ro-passwd | name of secret for LDAP credential |
| TZ | US/Pacific | time zone |

### Secrets

| Secret | Description |
| ------ | ----------- |
| ldap-ro-passwd | password for looking up LDAP users |

[![](https://images.microbadger.com/badges/license/instantlinux/dovecot.svg)](https://microbadger.com/images/instantlinux/dovecot "License badge")
