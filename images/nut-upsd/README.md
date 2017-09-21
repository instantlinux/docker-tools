## nut-upsd

The Network UPS Tools (nut) package in an Alpine container, with enough configuration to support Nagios monitoring of your UPS units.

### Usage

See the docker-compose.yml file provided here in the source directory; this needs to run in privileged mode in order to access USB devices.

This will expose TCP port 3493; to reach it with the standard Nagios plugin, set up a service to invoke:

```
/usr/lib/nagios/plugins/check_ups -H <dockerhost> -u <name> [ -p <port> ]
```

As a read-only service intended for monitoring, this container makes no attempt to lock down network security.

Verified with the most-common type of UPS, the APC consumer-grade product. Note that the usbhid-ups driver for APC requires you to provide the correct 12-digit hardware serial number. All other parameter defaults will work.

### Variables

Variable | Default | Description |
-------- | ------- | ----------- |
API_USER | upsmon| API user
DESCRIPTION | UPS | user-assigned description
DRIVER | usbhid-ups | driver (see [compatibility list](http://networkupstools.org/stable-hcl.html))
GROUP | nut | local group
NAME | ups | user-assigned config name
PORT | auto | device port on host
SECRET | nut-upsd-password | secret to use for API user
SERIAL | | hardware serial number of UPS
SERVER | master | master or slave priority for scripts
USER | nut | local user

### Secrets

| Secret | Description |
| ------ | ----------- |
| nut-upsd-password | Password for API user |
