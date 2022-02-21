## haproxy-keepalived
[![](https://img.shields.io/docker/v/instantlinux/haproxy-keepalived?sort=date)](https://hub.docker.com/r/instantlinux/haproxy-keepalived/tags "Version badge") [![](https://img.shields.io/docker/image-size/instantlinux/haproxy-keepalived?sort=date)](https://github.com/instantlinux/docker-tools/-/blob/main/images/haproxy-keepalived "Image badge") ![](https://img.shields.io/badge/platform-amd64%20arm64%20arm%2Fv6%20arm%2Fv7-blue "Platform badge") [![](https://img.shields.io/badge/dockerfile-latest-blue)](https://gitlab.com/instantlinux/docker-tools/-/blob/main/images/haproxy-keepalived/Dockerfile "dockerfile")


A load balancer with haproxy and keepalived (VRRP) to provide high-availability networking.

### Usage

Configuration is defined as files in volumes mounted as
/usr/local/etc/haproxy.d and /etc/keepalived/keepalived.conf.

* Define your local settings for haproxy under /etc/haproxy.d; see [man page](https://cbonte.github.io/haproxy-dconv/1.8/configuration.html); the entrypoint script here will concatenate multiple files.

* Define your keepalived settings in /etc/keepalived/keepalived.conf; see [man page](https://www.mankier.com/5/keepalived.conf).

* If you want to override the haproxy.cfg defined in this image, mount your own as /etc/haproxy.cfg with read-only set.

See the [haproxy-keepalived/examples/](https://github.com/instantlinux/docker-tools/blob/main/images/haproxy-keepalived/examples) directory under this git repository to get started.

This requires NET_ADMIN privileges: keepalived will run as root (but you can specify user `haproxy` or `keepalived_script` for the `vrrp_script` directive); haproxy will downgrade itself to user `haproxy` after startup. Also, you will need the ip_vs kernel module and ip_nonlocal set on the host running docker engine:
```
echo ip_vs >>/etc/modules.conf
echo net.ipv4.ip_nonlocal_bind=1 >/etc/sysctl.d/99-haproxy.conf
sysctl -p /etc/sysctl.d/99-haproxy.conf
```

After starting this service using [helm](https://github.com/instantlinux/docker-tools/tree/main/images/haproxy-keepalived/helm), _kubectl apply_ or _docker-compose_, you can connect to http://<host>:<port>/stats to view the haproxy stats page, with basic-auth username _haproxy_ and the password set in the secret defined below. This repo has complete instructions for
[building a kubernetes cluster](https://github.com/instantlinux/docker-tools/blob/main/k8s/README.md) where you can deploy [kubernetes.yaml](https://github.com/instantlinux/docker-tools/blob/main/images/haproxy-keepalived/kubernetes.yaml) using _make_ and customizing [Makefile.vars](https://github.com/instantlinux/docker-tools/blob/main/k8s/Makefile.vars) after cloning this repo:
~~~
git clone https://github.com/instantlinux/docker-tools.git
cd docker-tools/k8s
make haproxy-keepalived
~~~

### Variables

These variables can be passed to the image from kubernetes.yaml or docker-compose.yml as needed:

| Variable | Default | Description |
| -------- | ------- | ----------- |
|KEEPALIVE_CONFIG_ID| main | Which configuration to use (usually a hostname) |
|PORT_HAPROXY_STATS| 8080 | What port to use for stats page |
|STATS_ENABLE| yes | Whether to include stats | 
|STATS_SECRET|haproxy-stats-password | Secret to use for stats page |
|STATS_URI|/stats| URI for stats page |
|TIMEOUT|50000| Timeout for haproxy (ms)|
| TZ | UTC | time zone for syslog |

### Secrets

| Secret | Description |
| ------ | ----------- |
| haproxy-stats-password | password for haproxy user in stats page |

### Contributing

If you want to make improvements to this image, see [CONTRIBUTING](https://github.com/instantlinux/docker-tools/blob/main/CONTRIBUTING.md).

[![](https://img.shields.io/badge/license-GPL--2.0-red.svg)](https://choosealicense.com/licenses/gpl-2.0/ "License badge") [![](https://img.shields.io/badge/code-haproxy%2Fhaproxy-blue.svg)](https://github.com/haproxy/haproxy "Code repo") [![](https://img.shields.io/badge/code-acassen%2Fkeepalived-blue.svg)](https://github.com/acassen/keepalived "Code repo")
