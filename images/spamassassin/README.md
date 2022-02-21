## spamassassin
[![](https://img.shields.io/docker/v/instantlinux/spamassassin?sort=date)](https://hub.docker.com/r/instantlinux/spamassassin/tags "Version badge") [![](https://img.shields.io/docker/image-size/instantlinux/spamassassin?sort=date)](https://github.com/instantlinux/docker-tools/-/blob/main/images/spamassassin "Image badge") ![](https://img.shields.io/badge/platform-amd64%20arm64-blue "Platform badge") [![](https://img.shields.io/badge/dockerfile-latest-blue)](https://gitlab.com/instantlinux/docker-tools/-/blob/main/images/spamassassin/Dockerfile "dockerfile")

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
[building a kubernetes cluster](https://github.com/instantlinux/docker-tools/blob/main/k8s/README.md) where you can launch with [helm](https://github.com/instantlinux/docker-tools/tree/main/images/spamassassin/helm) or [kubernetes.yaml](https://github.com/instantlinux/docker-tools/blob/main/images/spamassassin/kubernetes.yaml) using _make_ and customizing [Makefile.vars](https://github.com/instantlinux/docker-tools/blob/main/k8s/Makefile.vars) after cloning this repo:
~~~
git clone https://github.com/instantlinux/docker-tools.git
cd docker-tools/k8s
make spamassassin
~~~

### Notes

At startup, if you've enabled razor2 the following warning is expected:
```
Use of uninitialized value in concatenation (.) or string at /usr/share/perl5/Razor2/Client/Config.pm line 442.
Use of uninitialized value in concatenation (.) or string at /usr/share/perl5/Razor2/Client/Config.pm line 443.
```

### Variables
These variables can be passed to the image from kubernetes.yaml or docker-compose.yml as needed:

| Variable | Default | Description |
| -------- | ------- | ----------- |
| CRON_HOUR | 1 |hour for daily rules update (1) |
| CRON_MINUTE | 30 | cron minute for update (30) |
| EXTRA_OPTIONS | --nouser-config | additional options |
| PYZOR_SITE | public.pyzor.org:24441 | pyzor URI |
| TZ | UTC | time zone |
| USERNAME | debian-spamd | user name to run as |

### Contributing

If you want to make improvements to this image, see [CONTRIBUTING](https://github.com/instantlinux/docker-tools/blob/main/CONTRIBUTING.md).

[![](https://img.shields.io/badge/license-Apache--2.0-red.svg)](https://choosealicense.com/licenses/apache-2.0/ "License badge") [![](https://img.shields.io/badge/code-apache_svn%2Fspamassassin-blue.svg)](https://svn.apache.org/viewvc/spamassassin "Code repo")
