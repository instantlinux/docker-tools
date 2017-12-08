## samba-dc

[![](https://images.microbadger.com/badges/version/instantlinux/samba-dc.svg)](https://microbadger.com/images/instantlinux/samba-dc "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/samba-dc.svg)](https://microbadger.com/images/instantlinux/samba-dc "Image badge") [![](https://images.microbadger.com/badges/commit/instantlinux/samba-dc.svg)](https://microbadger.com/images/instantlinux/samba-dc "Commit badge")

Samba domain controller.

### Usage

The most-common directives can be specified in environment variables as shown below.  If you need further customizations, put them in one or more files under mount point /etc/samba.d.

Basic requirements:

* A Domain Controller must have a static IP address and persistent DNS entry
* This container must be run in network_mode:host
* A hostname must be specified, which becomes the netbios name.

The directories /etc/samba and /var/lib/samba must be mounted as persistent volumes. If /var/lib/samba is empty, the "provision" or "join" action specified in DOMAIN_ACTION variable will be taken.

The most-common directives can be specified in environment variables as shown below. If you need further customizations, put them in one or more files under mount point /etc/samba/conf.d. If you want to add global settings, put those into the first file with a name like 0globals.conf -- they will be appended in alphabetical-sort sequence.

Test your configuration and/or manage contents of your directory using Apache Directory Studio. Make a connection on port 636 with method SSL encryption (ldaps); specify simple authentication with username <realm prefix>\<your name>. The ldaps certificate is self-signed so you'll need to accept it first.

### Status
* This is tested as a spare domain controller against Active Directory running on Windows Server 2008, and against other samba4 domain controllers
* The "provision" command to create a new DC does NOT yet work
* The "BIND_INTERFACES_ONLY" option does NOT work; a workaround is to invoke samba-tool domain join manually

### Variables

Variable | Default | Description |
-------- | ------- | ----------- |
ADMIN_PASSWORD_SECRET | samba-admin-password | admin secret, see below
ALLOW_DNS_UPDATES | disabled | enable DNS updates
BIND_INTERFACES_ONLY | no | specify IP addresses or interfaces
DOMAIN_ACTION | provision | set to 'join' if existing domain
DOMAIN_LOGONS | yes | support workgroup login
DOMAIN_MASTER | no | "WAN-wide browse list collation"--haha, see [man page](https://www.samba.org/samba/docs/man/manpages-3/smb.conf.5.html)
INTERFACES | lo eth0 | list of IP addresses or interfaces
LOG_LEVEL | 1 | log verbosity
MODEL | standard | process model: single, standard, thread
REALM | ad.example.com | active-directory DNS realm
SERVER_STRING | Samba Domain Controller | server identity
TZ | UTC | local timezone
WINBIND_TRUSTED_DOMAINS_ONLY | no | map Unix user to domain user
WINBIND_USE_DEFAULT_DOMAIN | yes | allow username without domain component
WORKGROUP | WORKGROUP | NT workgroup

### Secrets

Secret | Description
------ | -----------
samba-admin-password | domain-administrator pw

[![](https://images.microbadger.com/badges/license/instantlinux/samba-dc.svg)](https://microbadger.com/images/instantlinux/samba-dc "License badge")
