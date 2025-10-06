## nut-upsd
[![](https://img.shields.io/docker/v/instantlinux/nut-upsd?sort=date)](https://hub.docker.com/r/instantlinux/nut-upsd/tags "Version badge") [![](https://img.shields.io/docker/image-size/instantlinux/nut-upsd?sort=date)](https://github.com/instantlinux/docker-tools/tree/main/images/nut-upsd "Image badge") ![](https://img.shields.io/badge/platform-amd64%20arm64%20arm%2Fv6%20arm%2Fv7-blue "Platform badge") [![](https://img.shields.io/badge/dockerfile-latest-blue)](https://gitlab.com/instantlinux/docker-tools/-/blob/main/images/nut-upsd/Dockerfile "dockerfile")

The Network UPS Tools (nut) package in an Alpine container, with enough configuration to support Nagios monitoring of your UPS units. This multi-architecture image supports Intel/AMD and ARM (Raspberry Pi etc).

### Usage

See the kubernetes.yaml / docker-compose.yml files provided here in the source directory; this needs to run in privileged mode in order to access USB devices.

Pick a random password for the API user and place it in a Docker secret (if you're not using swarm or kubernetes, put it in the filepath as shown at bottom of docker-compose.yml, e.g. /var/adm/admin/secrets/nut-upsd-password).

This will expose TCP port 3493; to reach it with the standard Nagios plugin, set up a service to invoke:

```
/usr/lib/nagios/plugins/check_ups -H <dockerhost> -u <name> [ -p <port> ]
```

As a read-only service intended for monitoring, this container makes no attempt to lock down network security.

Verified with the most-common type of UPS, the APC consumer-grade product; Tripp Lite models also (probably) work. CyberPower models need a MAXAGE parameter set longer than default (25). Note that the usbhid-ups driver for APC requires you to provide the correct 12-digit hardware serial number. All other parameter defaults will work.

If you have a different model of UPS, contents of the files ups.conf, upsd.conf, upsmon.conf, and/or upsd.users can be overridden by mounting them to /etc/nut/local.

If you have more than one UPS connected to a host, run more than one copy of this container and bind the container port 3493 from each to a separate TCP port.

This repo has complete instructions for
[building a kubernetes cluster](https://github.com/instantlinux/docker-tools/blob/main/k8s/README.md) where you can launch with [helm](https://github.com/instantlinux/docker-tools/tree/main/images/nut-upsd/helm) or [kubernetes.yaml](https://github.com/instantlinux/docker-tools/blob/main/images/nut-upsd/kubernetes.yaml) using _make_ and customizing [Makefile.vars](https://github.com/instantlinux/docker-tools/blob/main/k8s/Makefile.vars) after cloning this repo:
~~~
git clone https://github.com/instantlinux/docker-tools.git
cd docker-tools/k8s
# This make target is defined in Makefile.instances
make nut-01
~~~

### Variables

These variables can be passed to the image from kubernetes.yaml or docker-compose.yml as needed:

Variable | Default | Description |
-------- | ------- | ----------- |
ACTIONS | | One or more user actions allowed (`set`, `fsd`)
API_USER | upsmon| API user
API_PASSWORD | | API password, if not using secret
DESCRIPTION | UPS | user-assigned description
DRIVER | usbhid-ups | driver (see [compatibility list](http://networkupstools.org/stable-hcl.html))
GROUP | nut | local group
INSTCMDS | | `all` or list of allowed commands, see [cmdvartab](https://github.com/networkupstools/nut/blob/master/data/cmdvartab) `CMDDESC` values
MAXAGE | 15 | seconds before declaring driver non-responsive
NAME | ups | user-assigned config name
NOTIFYCMD | | full path of script to run upon notification
NUT_DEBUG_LEVEL | 0 | verbosity of debug messages
NUT_QUIET_INIT_SSL | true | inhibit superfluous startup warning
NUT_QUIET_INIT_UPSNOTIFY | true | inhibit superfluous startup warning
POLLINTERVAL | | Poll Interval for ups.conf
PORT | auto | device port (e.g. /dev/ttyUSB0) on host
SDORDER | | UPS shutdown sequence, set to -1 to disable shutdown
SECRETNAME | nut-upsd-password | name of secret to use for API user
SERIAL | | hardware serial number of UPS
SERVER | primary | primary instance shuts down after secondaries
ULIMIT | 2048 | open-files ulimit
USER | nut | local user
VENDORID | | vendor ID for ups.conf
### Notes

To define a notify script, volume-mount it via your docker-compose file under /usr/local/bin or in your helm values overrides and set the NOTIFYCMD environment variable. (*Don't* mount any executable scripts under /etc/nut, put them under /usr/local).

If you need a driver other than `usbhid-ups`, the full list of supported drivers can be listed as follows:
```
docker run --rm --entrypoint /bin/ls instantlinux/nut-upsd /usr/lib/nut
```
The entrypoint script can set parameters based on the above environment variables; each driver has its own parameters (which can be configured by mounting your own ups.conf file) as documented:
```
MYDRIVER=liebert
docker run --rm --entrypoint /usr/lib/nut/$MYDRIVER instantlinux/nut-upsd -h
Network UPS Tools - Liebert MultiLink UPS driver 1.02 (3.15.0_alpha20210804-3402-gced1683082)
Warning: This is an experimental driver.
Some features may not function correctly.


usage: liebert -a <id> [OPTIONS]
  -a <id>        - autoconfig using ups.conf section <id>
                 - note: -x after -a overrides ups.conf settings

  -V             - print version, then exit
  -L             - print parseable list of driver variables
  -D             - raise debugging level
  -q             - raise log level threshold
  -h             - display this help
  -k             - force shutdown
  -i <int>       - poll interval
  -r <dir>       - chroot to <dir>
  -u <user>      - switch to <user> (if started as root)
  -x <var>=<val> - set driver variable <var> to <val>
                 - example: -x cable=940-0095B

Acceptable values for -x or ups.conf in this driver:

              Override manufacturer name : -x mfr=<value>
                     Override model name : -x model=<value>
```

For Tripp Lite models, you may need to specify VENDORID 09ae in the environment. Also check to see if you need a POLLINTERVAL setting. For any make or model, here's how to identify the idVendor and iSerial values from a root shell on your host:

```
# lsusb
 ...
Bus 001 Device 005: ID 051d:0002 American Power Conversion Uninterruptible Power Supply
# lsusb -D /dev/bus/usb/001/005
Device: ID 051d:0002 American Power Conversion Uninterruptible Power Supply
 ...
  idVendor           0x051d American Power Conversion
  idProduct          0x0002 Uninterruptible Power Supply
  bcdDevice            0.90
  iManufacturer           1 American Power Conversion
  iProduct                2 Back-UPS RS 1500G FW:865.L6 .D USB FW:L6
  iSerial                 3 4B1624P26350
```

If you require udev rules to set permissions, configure your host prior to running the container. For example:
```
cat >/etc/udev/rules.d/99-usb-serial.rules <<EOF
ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}==“09ae”, ATTRS{idProduct}==“2012”, MODE="0660", GROUP="nut"
EOF
udevadm control --reload-rules && udevadm trigger
```

When starting up under Debian trixie, an out-of-memory error can be prevented by setting the nofile ulimit to a smaller value than system default: see [issue #1672](https://github.com/networkupstools/nut/issues/1672). The default is set here to 2048.

If you see this error message on startup:
```
Unable to use old-style MONITOR line without a username
Convert it and add a username to upsd.users - see the documentation
```
the most likely cause is a missing or empty secret (`nut-upsd-password`).

### Secrets

If the API user needs a password, you have two ways to specify it: pass the value itself as environment variable API_PASSWORD (which isn't secure), or define a Docker secret as follows:

| Secret | Description |
| ------ | ----------- |
| nut-upsd-password | Password for API user |

### Contributing

If you want to make improvements to this image, see [CONTRIBUTING](https://github.com/instantlinux/docker-tools/blob/main/CONTRIBUTING.md).

[![](https://img.shields.io/badge/license-GPL--2.0-red.svg)](https://choosealicense.com/licenses/gpl-2.0/ "License badge") [![](https://img.shields.io/badge/code-networkupstools%2Fnut-blue.svg)](https://github.com/networkupstools/nut "Code repo")
