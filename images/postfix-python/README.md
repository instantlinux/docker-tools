## postfix-python
[![](https://img.shields.io/docker/v/instantlinux/postfix-python?sort=date)](https://hub.docker.com/r/instantlinux/postfix-python/tags "Version badge") [![](https://img.shields.io/docker/image-size/instantlinux/postfix-python?sort=date)](https://github.com/instantlinux/docker-tools/-/blob/main/images/postfix-python "Image badge") ![](https://img.shields.io/badge/platform-amd64%20arm64%20arm%2Fv6%20arm%2Fv7-blue "Platform badge") [![](https://img.shields.io/badge/dockerfile-latest-blue)](https://gitlab.com/instantlinux/docker-tools/-/blob/main/images/postfix-python/Dockerfile "dockerfile")

Postfix with python support. (Python needed for blacklist utility.) This repo has complete instructions for
[building a kubernetes cluster](https://github.com/instantlinux/docker-tools/blob/main/k8s/README.md) where you can launch with [helm](https://github.com/instantlinux/docker-tools/tree/main/images/postfix-python/helm) or [kubernetes.yaml](https://github.com/instantlinux/docker-tools/blob/main/images/postfix-python/kubernetes.yaml) using _make_ and customizing [Makefile.vars](https://github.com/instantlinux/docker-tools/blob/main/k8s/Makefile.vars) after cloning this repo:
~~~
git clone https://github.com/instantlinux/docker-tools.git
cd docker-tools/k8s
make postfix
~~~

See also the variables and secrets defined in base image [README](https://github.com/instantlinux/docker-tools/blob/main/images/postfix/README.md).

Messages flagged with a high spam score are diverted to subdirectories under /var/spool/postfix/quarantine. Set this path up as a volume mount if you want to preserve or process those messages with other tools.

### Variables

| Variable | Default | Description |
| -------- | ------- | ----------- |
| BLACKLIST_USER_SECRET | mysql-blacklist-user | MySQL cred secret name |
| CIDR_MIN_SIZE | 32 | size of netblock to blacklist |
| DB_HOST | dbhost | database host or IP |
| DB_NAME | blacklist | db name |
| DB_USER | blacklister | db user |
| HONEYPOT_ADDRS | honey@mydomain.com | comma-separated list of addresses |
| INBOUND_RELAY | "by mail.mydomain.com" | last inbound relay hop |
| SPAMLIMIT | 12 | any score above this will be quarantined |
| SPAMC_HOST | spamassassin | spamassassin host or IP |

### Secrets

| Secret | Description |
| ------ | ----------- |
| mysql-blacklist-user | username and password for MySQL db |

## Upgrade Notes

In versions 3.5.9 or later, there is a breaking change affecting the `postalias` command used to generate binary db files at startup.  If you have an entry in any of your `.cf` files under /etc/postfix that look like:
```
alias_database = hash:/etc/postfix/aliases
```
change them to:
```
alias_database = lmdb:/etc/postfix/aliases
```
You will no longer see the error message:
```
postalias: fatal: unsupported dictionary type: hash. Is the postfix-hash package installed?
```

### Contributing

If you want to make improvements to this image, see [CONTRIBUTING](https://github.com/instantlinux/docker-tools/blob/main/CONTRIBUTING.md).

[![](https://img.shields.io/badge/license-IPL--1.0-red.svg)](https://opensource.org/licenses/IPL-1.0 "License badge") [![](https://img.shields.io/badge/code-vdukhovni%2Fpostfix-blue.svg)](https://github.com/vdukhovni/postfix "Code repo")
