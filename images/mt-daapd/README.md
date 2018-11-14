## mt-daapd
[![](https://images.microbadger.com/badges/version/instantlinux/mt-daapd.svg)](https://microbadger.com/images/instantlinux/mt-daapd "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/mt-daapd.svg)](https://microbadger.com/images/instantlinux/mt-daapd "Image badge") [![](https://images.microbadger.com/badges/commit/instantlinux/mt-daapd.svg)](https://microbadger.com/images/instantlinux/mt-daapd "Commit badge")

This is Ron Pedde's [Firefly Media server](https://en.wikipedia.org/wiki/Firefly_Media_Server) which implements the Digital Audio Access Protocol for serving MP3 and other audio media formats from a directory mounted to this container onto a LAN.

Devices such as Roku, Sonos and other brands of audio players or applications such as the Amarok music play for Linux will be able to connect to this service using mDNS/DNS-SD (Avahi).

Requires --net=host in order to support mDNS. See the kubernetes.yaml or docker-compose.yml file for examples. To start, set environment variables as desired and invoke one of these commands:

```
docker-compose up -d
kubectl apply -f kubernetes.yaml
```

[![](https://images.microbadger.com/badges/license/instantlinux/mt-daapd.svg)](https://microbadger.com/images/instantlinux/mt-daapd "License badge")
