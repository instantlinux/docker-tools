## haproxy-keepalived
[![](https://images.microbadger.com/badges/version/instantlinux/haproxy-keepalived.svg)](https://microbadger.com/images/instantlinux/haproxy-keepalived "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/haproxy-keepalived.svg)](https://microbadger.com/images/instantlinux/haproxy-keepalived "Image badge") [![](https://images.microbadger.com/badges/commit/instantlinux/haproxy-keepalived.svg)](https://microbadger.com/images/instantlinux/haproxy-keepalived "Commit badge")

A load balancer with haproxy and keepalived (VRRP) to provide high-availability networking.

### Usage

Configuration is defined as files in volumes mounted as
/etc/haproxy.d and /etc/keepalived/keepalived.conf.

* Define your local settings for haproxy under /etc/haproxy.d; see [man page](https://cbonte.github.io/haproxy-dconv/1.8/configuration.html); the entrypoint script here will concatenate multiple files.

* Define your keepalived settings in /etc/keepalived/keepalived.conf; see [man page](https://www.mankier.com/5/keepalived.conf).

* If you want to override the haproxy.cfg defined in this image, mount your own as /etc/haproxy.cfg with read-only set.

See the [haproxy-keepalived/examples/](https://github.com/instantlinux/docker-tools/blob/master/images/haproxy-keepalived/examples) directory under this git repository to get started.

This requires NET_ADMIN privileges. Also, you will need the ip_vs kernel module and ip_nonlocal set on the host running docker engine:
```
echo ip_vs >>/etc/modules.conf
echo net.ipv4.ip_nonlocal_bind=1 >/etc/sysctl.d/99-haproxy.conf
sysctl -p /etc/sysctl.d/99-haproxy.conf
```

After starting this service using _kubectl apply_ or _docker-compose_, you can connect to http://<host>:<port>/stats to view the haproxy stats page, with basic-auth username _haproxy_ and the password set in the secret defined below. This repo has complete instructions for
[building a kubernetes cluster](https://github.com/instantlinux/docker-tools/blob/master/k8s/README.md) where you can deploy [kubernetes.yaml](https://github.com/instantlinux/docker-tools/blob/master/images/haproxy-keepalived/kubernetes.yaml) with the Makefile or:
~~~
cat kubernetes.yaml | envsubst | kubectl apply -f -
~~~

### Variables

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

[![](https://images.microbadger.com/badges/license/instantlinux/haproxy-keepalived.svg)](https://microbadger.com/images/instantlinux/haproxy-keepalived "License badge")
