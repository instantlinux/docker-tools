## dovecot
[![](https://img.shields.io/docker/v/instantlinux/dovecot?sort=date)](https://hub.docker.com/r/instantlinux/dovecot/tags "Version badge") [![](https://img.shields.io/docker/image-size/instantlinux/dovecot?sort=date)](https://github.com/instantlinux/docker-tools/-/blob/main/images/dovecot "Image badge") ![](https://img.shields.io/badge/platform-amd64%20arm64%20arm%2Fv6%20arm%2Fv7-blue "Platform badge") [![](https://img.shields.io/badge/dockerfile-latest-blue)](https://gitlab.com/instantlinux/docker-tools/-/blob/main/images/dovecot/Dockerfile "dockerfile")

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
  wget https://raw.githubusercontent.com/dovecot/core/release-2.3.4/doc/mkcert.sh
  wget https://dovecot.org/doc/dovecot-openssl.cnf
  # (edit dovecot-openssl.cnf to suit)
  ./mkcert.sh
  ```

For settings, see etc-example directory and [helm]((https://github.com/instantlinux/docker-tools/tree/main/images/dovecot/helm) / kubernetes.yaml / docker-compose.yml. The [k8s/Makefile.vars](https://github.com/instantlinux/docker-tools/blob/main/k8s/Makefile.vars) file defines default values.

Also configure postfix as described in the postfix image.

This repo has complete instructions for
[building a kubernetes cluster](https://github.com/instantlinux/docker-tools/blob/main/k8s/README.md) where you can launch with [helm](https://github.com/instantlinux/docker-tools/tree/main/images/dovecot/helm) or [kubernetes.yaml](https://github.com/instantlinux/docker-tools/blob/main/images/dovecot/kubernetes.yaml) using _make_ and customizing [Makefile.vars](https://github.com/instantlinux/docker-tools/blob/main/k8s/Makefile.vars) after cloning this repo:
~~~
git clone https://github.com/instantlinux/docker-tools.git
cd docker-tools/k8s
make dovecot
~~~

See the Makefile and Makefile.vars files under k8s directory for default values referenced within kubernetes.yaml.

### Variables

| Variable | Default | Description |
| -------- | ------- | ----------- |
| LDAP_PASSWD_SECRET | ldap-ro-passwd | name of secret for LDAP credential |
| SSL_DH |  | Filename (in conf.local) of DH parameters |
| TZ | UTC | time zone |

Need more configurability? Edit the ConfigMap defined in kubernetes.yaml.

### Secrets

| Secret | Description |
| ------ | ----------- |
| ldap-ro-passwd | password for looking up LDAP users |
| *key.pem | keyfile specified for ssl_dh certificate |

### Contributing

If you want to make improvements to this image, see [CONTRIBUTING](https://github.com/instantlinux/docker-tools/blob/main/CONTRIBUTING.md).

[![](https://img.shields.io/badge/license-Apache--2.0-red.svg)](https://choosealicense.com/licenses/apache-2.0/ "License badge") [![](https://img.shields.io/badge/code-dovecot%2Fcore-blue.svg)](https://github.com/dovecot/core "Code repo")

### Upgrade Notes

* When upgrading to 2.3.14+, replace any references to `hash:` with `lmdb:` in your config files.
