## dovecot
[![](https://images.microbadger.com/badges/version/instantlinux/dovecot.svg)](https://microbadger.com/images/instantlinux/dovecot "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/dovecot.svg)](https://microbadger.com/images/instantlinux/dovecot "Image badge") [![](https://images.microbadger.com/badges/commit/instantlinux/dovecot.svg)](https://microbadger.com/images/instantlinux/dovecot "Commit badge")

The dovecot imapd daemon in a small Alpine Linux container, with
postfix for local delivery and procmail for filtering.

### Usage

Configuration is defined as files in a volume mounted as
/etc/dovecot/conf.local. Within that directory:

* Define your local settings as dovecot.conf.

* If you have an LDAP server, put its settings in dovecot-ldap.conf.

* (Optional, to save startup time) generate a dh.pem file for TLS:
  ```
  openssl dhparam -dsaparam -out dh.pem 4096
  ```
* (Optional, to save startup time) generate self-signed server.pem and server.key files for mounting to /etc/ssl/dovecot
  ```
  wget https://raw.githubusercontent.com/dovecot/core/release-2.3.2/doc/mkcert.sh
  # (edit dovecot-openssl.cnf to suit)
  ./mkcert.sh
  ```

Also configure postfix as described in the postfix image.

See etc-example directory and kubernetes.yaml / docker-compose.yml.

This repo has complete instructions for
[building a kubernetes cluster](https://github.com/instantlinux/docker-tools/blob/master/k8s/README.md) where you can deploy [kubernetes.yaml](kubernetes.yaml) with the Makefile or:
~~~
cat kubernetes.yaml | envsubst | kubectl apply -f -
~~~

### Variables

| Variable | Default | Description |
| -------- | ------- | ----------- |
| LDAP_PASSWD_SECRET | ldap-ro-passwd | name of secret for LDAP credential |
| SSL_DH |  | Filename (in conf.local) of DH parameters |
| TZ | UTC | time zone |

### Secrets

| Secret | Description |
| ------ | ----------- |
| ldap-ro-passwd | password for looking up LDAP users |
| *key.pem | keyfile specified for ssl_dh certificate |

[![](https://images.microbadger.com/badges/license/instantlinux/dovecot.svg)](https://microbadger.com/images/instantlinux/dovecot "License badge")
