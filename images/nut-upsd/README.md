## nut-upsd
[![](https://images.microbadger.com/badges/version/instantlinux/nut-upsd.svg)](https://microbadger.com/images/instantlinux/nut-upsd "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/nut-upsd.svg)](https://microbadger.com/images/instantlinux/nut-upsd "Image badge") [![](https://images.microbadger.com/badges/commit/instantlinux/nut-upsd.svg)](https://microbadger.com/images/instantlinux/nut-upsd "Commit badge")

The Network UPS Tools (nut) package in an Alpine container, with enough configuration to support Nagios monitoring of your UPS units.

### Usage

See the kubernetes.yaml / docker-compose.yml files provided here in the source directory; this needs to run in privileged mode in order to access USB devices.

Pick a random password for the API user and place it in a Docker secret (if you're not using swarm or kubernetes, put it in the filepath as shown at bottom of docker-compose.yml, e.g. /var/adm/admin/secrets/nut-upsd-password).

This will expose TCP port 3493; to reach it with the standard Nagios plugin, set up a service to invoke:

```
/usr/lib/nagios/plugins/check_ups -H <dockerhost> -u <name> [ -p <port> ]
```

As a read-only service intended for monitoring, this container makes no attempt to lock down network security.

Verified with the most-common type of UPS, the APC consumer-grade product. Note that the usbhid-ups driver for APC requires you to provide the correct 12-digit hardware serial number. All other parameter defaults will work.

If you have more than one UPS connected to a host, run more than one copy of this container and bind the container port 3493 from each to a separate TCP port.

This repo has complete instructions for
[building a kubernetes cluster](https://github.com/instantlinux/docker-tools/blob/master/k8s/README.md) where you can deploy [kubernetes.yaml](https://github.com/instantlinux/docker-tools/blob/master/images/nut-upsd/kubernetes.yaml) with the Makefile or:
~~~
cat kubernetes.yaml | envsubst | kubectl apply -f -
~~~

### Variables

Variable | Default | Description |
-------- | ------- | ----------- |
API_USER | upsmon| API user
DESCRIPTION | UPS | user-assigned description
DRIVER | usbhid-ups | driver (see [compatibility list](http://networkupstools.org/stable-hcl.html))
GROUP | nut | local group
NAME | ups | user-assigned config name
PORT | auto | device port (e.g. /dev/ttyUSB0) on host
SECRET | nut-upsd-password | secret to use for API user
SERIAL | | hardware serial number of UPS
SERVER | master | master or slave priority for scripts
USER | nut | local user

### Secrets

| Secret | Description |
| ------ | ----------- |
| nut-upsd-password | Password for API user |

[![](https://images.microbadger.com/badges/license/instantlinux/nut-upsd.svg)](https://microbadger.com/images/instantlinux/nut-upsd "License badge")
