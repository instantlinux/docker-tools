## udp-nginx-proxy
[![](https://img.shields.io/docker/v/instantlinux/udp-nginx-proxy?sort=date)](https://hub.docker.com/r/instantlinux/udp-nginx-proxy/tags "Version badge") [![](https://img.shields.io/docker/image-size/instantlinux/udp-nginx-proxy?sort=date)](https://github.com/instantlinux/docker-tools/-/blob/main/images/udp-nginx-proxy "Image badge") ![](https://img.shields.io/badge/platform-amd64%20arm64%20arm%2Fv6%20arm%2Fv7-blue "Platform badge") [![](https://img.shields.io/badge/dockerfile-latest-blue)](https://gitlab.com/instantlinux/docker-tools/-/blob/main/images/udp-nginx-proxy/Dockerfile "dockerfile")

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

### Contributing

If you want to make improvements to this image, see [CONTRIBUTING](https://github.com/instantlinux/docker-tools/blob/main/CONTRIBUTING.md).

[![](https://img.shields.io/badge/license-Apache--2.0-red.svg)](https://choosealicense.com/licenses/apache-2.0/ "License badge") [![](https://img.shields.io/badge/code-nginx_org%2Fnginx-blue.svg)](http://hg.nginx.org/nginx "Code repo")
