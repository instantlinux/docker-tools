## rsyslogd
[![](https://images.microbadger.com/badges/version/instantlinux/rsyslogd.svg)](https://microbadger.com/images/instantlinux/rsyslogd "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/rsyslogd.svg)](https://microbadger.com/images/instantlinux/rsyslogd "Image badge") [![](https://images.microbadger.com/badges/commit/instantlinux/rsyslogd.svg)](https://microbadger.com/images/instantlinux/rsyslogd "Commit badge")

Run your central rsyslog in a high-availability container on top of shared storage. Then send all that into Splunk or wherever.

Why is this image customized? I couldn't find a stock Docker rsyslogd image that includes logrotate; the Docker community seems to have run amok splitting out trivial tools that really belong together. This also includes the rsyslog-mysql module (boosts image size from 7.4MB to 12.7MB).

### Usage

Set up a load balancer with your desired port number and aim it at this. Put your /etc/rsyslog.d and /etc/logrotate.d customizations into read-only volume mounts. There's really not much to this.

An example compose file is provided here in docker-compose.yml. This repo has complete instructions for
[building a kubernetes cluster](https://github.com/instantlinux/docker-tools/blob/master/k8s/README.md) where you can deploy [kubernetes.yaml](https://github.com/instantlinux/docker-tools/blob/master/images/rsyslogd/kubernetes.yaml) with the Makefile or:
~~~
cat kubernetes.yaml | envsubst | kubectl apply -f -
~~~

[![](https://images.microbadger.com/badges/license/instantlinux/rsyslogd.svg)](https://microbadger.com/images/instantlinux/rsyslogd "License badge")
