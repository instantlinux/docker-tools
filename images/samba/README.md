## samba

[![](https://images.microbadger.com/badges/version/instantlinux/samba.svg)](https://microbadger.com/images/instantlinux/samba "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/samba.svg)](https://microbadger.com/images/instantlinux/samba "Image badge") [![](https://images.microbadger.com/badges/commit/instantlinux/samba.svg)](https://microbadger.com/images/instantlinux/samba "Commit badge")

Samba as a file server. This is stripped down to the basics to enable greatest flexibility.

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
[building a kubernetes cluster](https://github.com/instantlinux/docker-tools/blob/master/k8s/README.md) where you can deploy [kubernetes.yaml](https://github.com/instantlinux/docker-tools/blob/master/images/samba/kubernetes.yaml) with the Makefile or:
~~~
cat kubernetes.yaml | envsubst | kubectl apply -f -
~~~

### Variables

Variable | Default | Description |
-------- | ------- | ----------- |
DOMAIN_LOGONS | no | enable workgroup logon
LOGON_DRIVE | H | initial drive mapping
NETBIOS_NAME | samba | server name
SERVER_STRING | "Samba Server" | server banner string
TZ | UTC | local timezone
WORKGROUP | WORKGROUP | workgroup name

[![](https://images.microbadger.com/badges/license/instantlinux/samba.svg)](https://microbadger.com/images/instantlinux/samba "License badge")
