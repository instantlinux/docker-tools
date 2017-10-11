## udp-nginx-proxy
[![](https://images.microbadger.com/badges/version/instantlinux/udp-nginx-proxy.svg)](https://microbadger.com/images/instantlinux/udp-nginx-proxy "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/udp-nginx-proxy.svg)](https://microbadger.com/images/instantlinux/udp-nginx-proxy "Image badge") [![](https://images.microbadger.com/badges/commit/instantlinux/udp-nginx-proxy.svg)](https://microbadger.com/images/instantlinux/udp-nginx-proxy "Commit badge")

The missing feature of haproxy: UDP, provided by nginx. The main
use-case for this is to make more than one DNS server available at a
single IP address for high-availability. It can also remap specialized
DNS services from one UDP port to another.

### Usage

See the docker-compose.yml file provided here in the source directory;
you will probably need to run it in network:host mode.

A customized configuration can be volume-mounted as /usr/local/lib/udp.conf.

### Variables

Variable | Default | Description |
-------- | ------- | ----------- |
BACKENDS | self | space-separated list of backend IP or hostnames
INTERFACE | eth0 | interface to listen on
IP_LISTEN | self | IP address to bind to
PORT_BACKEND | 53 | UDP port number of backend servers
PORT_LISTEN | 53 | port to listen on

[![](https://images.microbadger.com/badges/license/instantlinux/udp-nginx-proxy.svg)](https://microbadger.com/images/instantlinux/udp-nginx-proxy "License badge")
