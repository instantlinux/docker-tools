## mt-daapd
[![](https://img.shields.io/docker/v/instantlinux/mt-daapd?sort=date)](https://hub.docker.com/r/instantlinux/mt-daapd/tags "Version badge") [![](https://img.shields.io/docker/image-size/instantlinux/mt-daapd?sort=date)](https://github.com/instantlinux/docker-tools/-/blob/main/images/mt-daapd "Image badge") ![](https://img.shields.io/badge/platform-amd64%20arm64%20arm%2Fv6%20arm%2Fv7-blue "Platform badge") [![](https://img.shields.io/badge/dockerfile-latest-blue)](https://gitlab.com/instantlinux/docker-tools/-/blob/main/images/mt-daapd/Dockerfile "dockerfile")

This is Ron Pedde's [Firefly Media server](https://en.wikipedia.org/wiki/Firefly_Media_Server) which implements the Digital Audio Access Protocol for serving MP3 and other audio media formats from a directory mounted to this container onto a LAN.

Devices such as Roku, Sonos and other brands of audio players or applications such as the Amarok music play for Linux will be able to connect to this service using mDNS/DNS-SD (Avahi).

Requires --net=host in order to support mDNS. See the [kubernetes.yaml](https://github.com/instantlinux/docker-tools/blob/main/images/mt-daapd/kubernetes.yaml) or [helm](https://github.com/instantlinux/docker-tools/tree/main/images/mt-daapd/helm) / [docker-compose.yml](docker-compose.yml) file for examples. To start, set environment variables as desired and invoke this:

~~~
docker-compose up -d
~~~
or under Kubernetes customize [Makefile.vars](https://github.com/instantlinux/docker-tools/blob/main/k8s/Makefile.vars) and invoke _make_ after cloning this repo:
~~~
git clone https://github.com/instantlinux/docker-tools.git
cd docker-tools/k8s
make mt-daapd
~~~

Volume attachments: mount the media as /srv/music; add an index cache mount /var/cache/forked-daapd and a log path /var/log if avahi logging is desired. Most activity is logged to the container's standard output.

### Variables

| Variable | Default | Description |
| -------- | ------- | ----------- |
| SERVER_BANNER | Firefly Media on Ubuntu | Name of service |

### Contributing

If you want to make improvements to this image, see [CONTRIBUTING](https://github.com/instantlinux/docker-tools/blob/main/CONTRIBUTING.md).

[![](https://img.shields.io/badge/license-GPL--2.0-red.svg)](https://choosealicense.com/licenses/gpl-2.0/ "License badge") [![](https://img.shields.io/badge/code-ejurgensen%2Fforked_daapd-blue.svg)](https://github.com/ejurgensen/forked-daapd "Code repo")
