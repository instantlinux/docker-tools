## postfix-python
[![](https://images.microbadger.com/badges/version/instantlinux/postfix-python.svg)](https://microbadger.com/images/instantlinux/postfix-python "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/postfix-python.svg)](https://microbadger.com/images/instantlinux/postfix-python "Image badge") [![](https://images.microbadger.com/badges/commit/instantlinux/postfix-python.svg)](https://microbadger.com/images/instantlinux/postfix-python "Commit badge")

Postfix with python support. (Python needed for blacklist utility.) This repo has complete instructions for
[building a kubernetes cluster](https://github.com/instantlinux/docker-tools/blob/master/k8s/README.md) where you can deploy [kubernetes.yaml](https://github.com/instantlinux/docker-tools/blob/master/images/postfix-python/kubernetes.yaml) using _make_ and customizing [Makefile.vars](https://github.com/instantlinux/docker-tools/blob/master/k8s/Makefile.vars) after cloning this repo:
~~~
git clone https://github.com/instantlinux/docker-tools.git
cd docker-tools/k8s
make postfix
~~~

See also the variables and secrets defined in base image [README](https://github.com/instantlinux/docker-tools/blob/master/images/postfix/README.md).

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

[![](https://images.microbadger.com/badges/license/instantlinux/postfix-python.svg)](https://microbadger.com/images/instantlinux/postfix-python "License badge") [![](https://img.shields.io/badge/code-vdukhovni%2Fpostfix-blue.svg)](https://github.com/vdukhovni/postfix "Code repo")
