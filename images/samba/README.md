## samba
[![](https://img.shields.io/docker/v/instantlinux/samba?sort=date)](https://hub.docker.com/r/instantlinux/samba/tags "Version badge") [![](https://img.shields.io/docker/image-size/instantlinux/samba?sort=date)](https://github.com/instantlinux/docker-tools/-/blob/main/images/samba "Image badge") ![](https://img.shields.io/badge/platform-amd64%20arm64%20arm%2Fv6%20arm%2Fv7-blue "Platform badge") [![](https://img.shields.io/badge/dockerfile-latest-blue)](https://gitlab.com/instantlinux/docker-tools/-/blob/main/images/samba/Dockerfile "dockerfile")

Samba as a file server. This is stripped down to the basics to enable greatest flexibility. Supported on multiple architectures.

### Usage

The most-common directives can be specified in environment variables as shown below. If you need further customizations, put them in one or more files under mount point /etc/samba/conf.d. If you want to add global settings, put those into the first file with a name like 0globals.conf -- they will be appended in alphabetical-sort sequence.

Samba requires mapping between Unix user IDs and Windows identities. The simplest way to do that is create a file users.sh mounted under /etc/samba/conf.d with group and username entries in this form:
```
addgroup -g 1234 groupname
adduser -D -H -G groupname -u 5678 myself
```

and set passwords in a file /var/lib/samba/private/passwd.tdb using the smbpasswd utility after starting the container:
```
docker exec -it samba_app_1 smbpasswd -a myself
New SMB password:
Retype new SMB password:
Added user myself.
```
See [Samba IDMAP](https://www.samba.org/samba/docs/man/Samba-HOWTO-Collection/idmapper.html) documentation for the many other supported identity mapping options. This repo has complete instructions for
[building a kubernetes cluster](https://github.com/instantlinux/docker-tools/blob/main/k8s/README.md) where you can launch with [helm](https://github.com/instantlinux/docker-tools/tree/main/images/samba/helm) or [kubernetes.yaml](https://github.com/instantlinux/docker-tools/blob/main/images/samba/kubernetes.yaml) using _make_ and customizing [Makefile.vars](https://github.com/instantlinux/docker-tools/blob/main/k8s/Makefile.vars) after cloning this repo:
~~~
git clone https://github.com/instantlinux/docker-tools.git
cd docker-tools/k8s
make samba
~~~

### Variables

These variables can be passed to the image from helm values.yaml, kubernetes.yaml or docker-compose.yml as needed:

Variable | Default | Description |
-------- | ------- | ----------- |
DOMAIN_LOGONS | no | enable workgroup logon
LOGON_DRIVE | H | initial drive mapping
NETBIOS_NAME | samba | server name
SERVER_STRING | "Samba Server" | server banner string
TZ | UTC | local timezone
WORKGROUP | WORKGROUP | workgroup name

### Contributing

If you want to make improvements to this image, see [CONTRIBUTING](https://github.com/instantlinux/docker-tools/blob/main/CONTRIBUTING.md).

[![](https://img.shields.io/badge/license-GPL--3.0-red.svg)](https://choosealicense.com/licenses/gpl-3.0/ "License badge") [![](https://img.shields.io/badge/code-samba_team%2Fsamba-blue.svg)](https://gitlab.com/samba-team/samba "Code repo")
