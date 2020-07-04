## rsyslogd
[![](https://img.shields.io/docker/v/instantlinux/rsyslogd?sort=date)](https://microbadger.com/images/instantlinux/rsyslogd "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/rsyslogd.svg)](https://microbadger.com/images/instantlinux/rsyslogd "Image badge") ![](https://img.shields.io/badge/platform-amd64%20arm64%20arm%2Fv6%20arm%2Fv7-blue "Platform badge") [![](https://img.shields.io/badge/dockerfile-latest-blue)](https://gitlab.com/instantlinux/docker-tools/-/blob/master/images/rsyslogd/Dockerfile "dockerfile")

Run your central rsyslog in a high-availability container on top of shared storage. Then send all that into Splunk or wherever.

Why is this image customized? I couldn't find a stock Docker rsyslogd image that includes logrotate. This also includes the rsyslog-mysql module, which you can use to send logs to a database.

### Usage

Set up a load balancer with your desired port number and aim it at this. Put your /etc/rsyslog.d and /etc/logrotate.d customizations into read-only volume mounts. Map /var/log to a persistent volume if you want to preserve it. There's really not much to this.

Example kubernetes and docker-compose resource definition files are provided here. This repo has complete instructions for
[building a kubernetes cluster](https://github.com/instantlinux/docker-tools/blob/master/k8s/README.md) where you can deploy [kubernetes.yaml](https://github.com/instantlinux/docker-tools/blob/master/images/rsyslogd/kubernetes.yaml) using _make_ and customizing [Makefile.vars](https://github.com/instantlinux/docker-tools/blob/master/k8s/Makefile.vars) after cloning this repo:
~~~
git clone https://github.com/instantlinux/docker-tools.git
cd docker-tools/k8s
make rsyslogd
~~~

### Variables

| Variable | Default | Description |
| -------- | ------- | ----------- |
| TZ       | UTC     | timezone    |

Most configuration is done via config file; see the ConfigMap defined in kubernetes.yaml.

[![](https://img.shields.io/badge/license-GPL--3.0-red.svg)](https://choosealicense.com/licenses/gpl-3.0/ "License badge") [![](https://img.shields.io/badge/code-rsyslog%2Frsyslog-blue.svg)](https://github.com/rsyslog/rsyslog "Code repo")
