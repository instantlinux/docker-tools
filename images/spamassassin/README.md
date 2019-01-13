## spamassassin
[![](https://images.microbadger.com/badges/version/instantlinux/spamassassin.svg)](https://microbadger.com/images/instantlinux/spamassassin "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/spamassassin.svg)](https://microbadger.com/images/instantlinux/spamassassin "Image badge") [![](https://images.microbadger.com/badges/commit/instantlinux/spamassassin.svg)](https://microbadger.com/images/instantlinux/spamassassin "Commit badge")

This image includes pyzor, razor2 and dcc (with proper initialization of
razor2 upon container start). The rules update can be scheduled to run at an
interval specified in cron.

### Usage
To add local rules, create a rules file for
/etc/mail/spamassassin/local.cf and map that file into the
container. To ensure that updated rules survive container restart,
make sure the /var/lib/spamassassin home directory is mounted to a
named volume. See the docker-compose.yml file here for an example.
This repo has complete instructions for
[building a kubernetes cluster](https://github.com/instantlinux/docker-tools/blob/master/k8s/README.md) where you can deploy [kubernetes.yaml](kubernetes.yaml) with the Makefile or:
~~~
cat kubernetes.yaml | envsubst | kubectl apply -f -
~~~

### Variables
| Variable | Default | Description |
| -------- | ------- | ----------- |
| CRON_HOUR | 1 |hour for daily rules update (1) |
| CRON_MINUTE | 30 | cron minute for update (30) |
| EXTRA_OPTIONS | --nouser-config | additional options |
| PYZOR_SITE | public.pyzor.org:24441 | pyzor URI |
| TZ | UTC | time zone |
| USERNAME | debian-spamd | user name to run as |
[![](https://images.microbadger.com/badges/license/instantlinux/spamassassin.svg)](https://microbadger.com/images/instantlinux/spamassassin "License badge")
