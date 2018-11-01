## haproxy-keepalived
[![](https://images.microbadger.com/badges/version/instantlinux/haproxy-keepalived.svg)](https://microbadger.com/images/instantlinux/haproxy-keepalived "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/haproxy-keepalived.svg)](https://microbadger.com/images/instantlinux/haproxy-keepalived "Image badge") [![](https://images.microbadger.com/badges/commit/instantlinux/haproxy-keepalived.svg)](https://microbadger.com/images/instantlinux/haproxy-keepalived "Commit badge")

A load balancer with haproxy and keepalived for VRRP to provide high-availability services.

### Usage

Configuration is defined as files in volumes mounted as
/etc/haproxy.d and /etc/keepalived/keepalived.conf.

* Define your local settings for haproxy files under /etc/haproxy.d.

* Define your keepalived settings in /etc/keepalived/keepalived.conf.

This requires NET_ADMIN privileges. Also, you will need the ip_vs kernel module on the host running docker engine:
```
echo ip_vs >>/etc/modules.conf
```

### Variables

| Variable | Default | Description |
| -------- | ------- | ----------- |
|KEEPALIVE_CONFIG_ID| main | Which configuration to use (usually a hostname) |
|STATS_SECRET|haproxy-stats-password | Secret to use for stats page |
|TIMEOUT|50000|timeout for haproxy (ms)|
| TZ | UTC | time zone for syslog |

### Secrets

| Secret | Description |
| ------ | ----------- |
| haproxy-stats-password | password for haproxy user in stats page |

[![](https://images.microbadger.com/badges/license/instantlinux/haproxy-keepalived.svg)](https://microbadger.com/images/instantlinux/haproxy-keepalived "License badge")
