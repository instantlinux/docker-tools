## samba-dc
[![](https://img.shields.io/docker/v/instantlinux/samba-dc?sort=date)](https://hub.docker.com/r/instantlinux/samba-dc/tags "Version badge") [![](https://img.shields.io/docker/image-size/instantlinux/samba-dc?sort=date)](https://github.com/instantlinux/docker-tools/-/blob/main/images/samba-dc "Image badge") ![](https://img.shields.io/badge/platform-amd64%20arm64%20arm%2Fv6%20arm%2Fv7-blue "Platform badge") [![](https://img.shields.io/badge/dockerfile-latest-blue)](https://gitlab.com/instantlinux/docker-tools/-/blob/main/images/samba/Dockerfile "dockerfile")

Samba domain controller.

### Usage
The most-common directives can be specified in environment variables as shown below.  If you need further customizations, put them in one or more files under mount point /etc/samba.d.

Basic requirements:

* A Domain Controller must have a static IP address and persistent DNS entry
* This container must be run in network_mode:host, and with cap_add:CAP_SYS_ADMIN privs
* A NETBIOS_NAME or hostname must be specified, which becomes the netbios name.

The directories /etc/samba and /var/lib/samba must be mounted as persistent volumes. If /var/lib/samba is empty, the "provision" or "join" action specified in DOMAIN_ACTION variable will be taken.

The most-common directives can be specified in environment variables as shown below. If you need further customizations, put them in one or more files under mount point /etc/samba/conf.d. If you want to add global settings, put those into the first file with a name like 0globals.conf -- they will be appended in alphabetical-sort sequence.

Test your configuration and/or manage contents of your directory using Apache Directory Studio. Make a connection on port 636 with method SSL encryption (ldaps); specify simple authentication with username <realm prefix>\<your name>. The ldaps certificate is self-signed so you'll need to accept it first.

This repo has complete instructions for
[building a kubernetes cluster](https://github.com/instantlinux/docker-tools/blob/main/k8s/README.md) where you can launch with [helm](https://github.com/instantlinux/docker-tools/tree/main/images/samba-dc/helm) or [kubernetes.yaml](https://github.com/instantlinux/docker-tools/blob/main/images/samba-dc/kubernetes.yaml)  using _make_ and customizing [Makefile.vars](https://github.com/instantlinux/docker-tools/blob/main/k8s/Makefile.vars) after cloning this repo:
~~~
git clone https://github.com/instantlinux/docker-tools.git
cd docker-tools/k8s
# This take target is defined in Makefile.instances
make dc03
~~~

### Status
* The "join" command is tested as a spare domain controller against Active Directory running on Windows Server 2008, and against other samba4 domain controllers.
* The "provision" is tested as a Samba4 domain controller with a Windows 7 client.
* The "BIND_INTERFACES_ONLY" option is working now.
* It is very difficult to get multiple instances of samba-dc replicating with one another. I've given up on it as of version 4.8.8; perhaps a future version will fix these problems.

### Variables
Variable | Default | Description |
-------- | ------- | ----------- |
ADMIN_PASSWORD_SECRET | samba-admin-password | admin secret, see below
ALLOW_DNS_UPDATES | secure | enable DNS updates
BIND_INTERFACES_ONLY | yes | specify IP addresses or interfaces
DOMAIN_ACTION | provision | set to 'join' if existing domain
DOMAIN_LOGONS | yes | support workgroup login
DOMAIN_MASTER | no | "WAN-wide browse list collation"--haha, see [man page](https://www.samba.org/samba/docs/man/manpages-3/smb.conf.5.html)
INTERFACES | lo eth0 | list of IP addresses or interfaces
LOG_LEVEL | 1 | log verbosity
MODEL | standard | process model: single, standard, thread
NETBIOS_NAME | (hostname -s) | the NETBIOS name
REALM | ad.example.com | active-directory DNS realm
SERVER_STRING | Samba Domain Controller | server identity
TZ | UTC | local timezone
WINBIND_USE_DEFAULT_DOMAIN | yes | allow username without domain component
WORKGROUP | AD | workgroup (realm prefix - poorly documented)

### Secrets
This is only needed at first run, for samba domain provision or join. Do NOT leave your domain-controller administrator secret activated at any other time.
For clarity, this is a docker-secret with the initial Samba admin password, not the password itself.

Secret | Description
------ | -----------
samba-admin-password | domain-administrator pw

Secrets can be specified as kubernetes secrets, files (see the _secrets_ section of the example [docker-compose.yml](https://github.com/instantlinux/docker-tools/blob/main/images/samba-dc/docker-compose.yml) provided in this repo), or as swarm secrets.

### Notes
Getting a domain-controller cluster up and running properly requires a lot of correctly-configured trust relationships established between domain controllers, and Samba's documentation of error messages and problem-resolutions is pretty thin. If you're only running this version of samba, it's likely there will be few problems. But in a mixed environment with Microsoft Active Directory servers and/or older versions of samba4, you're bound to run into problems that require tweaking. A few diagnostic commands are available within this container; here are notes that might help you get up and running more quickly:

* You need an obscure DNS entry for your new domain controller that sometimes isn't automatically set up via samba-tool: go onto the instance and type the following "magic" to do it:
```
export LDB_MODULES_PATH=/usr/lib/samba/ldb
ldbsearch -H /var/lib/samba/private/sam.ldb '(invocationid=*)' \
 --cross-ncs objectguid|grep -i -B 1 -A 1 <new dc hostname>
samba-tool dns add dc01 _msdcs.ether.ci.net <guid from above> \
 CNAME <new dc fqdn> -UAdministrator
```

* If you're running with older versions of samba and see any DRS replication errors mentioning LDAP SASL, add this configuration under /etc/samba/conf.d/0global.conf:
```
ldap server require strong auth = no
```
* Look for errors in replication:
```
samba-tool drs showrepl
```
* Check the local databases:
```
samba-tool dbcheck
samba-tool drs kcc
```
* Make sure replication works both ways (copy the <NC> names like dc=foo that you see in output of drs showrepl):
```
./samba-tool drs replicate dc1 dc2 dc=<foo...>,dc=<suffix> --full-sync
./samba-tool drs replicate dc2 dc1 dc=<foo...>,dc=<suffix> --full-sync
```
* Using nslookup or host, list the DNS records for the new domain controller's FQDN. It should only have one record, with the correct IP address. Get rid of spurious ones and add the correct one using commands like:
```
samba-tool dns add <dc> <domain> <dc> A <ip> -Uadministrator
samba-tool dns delete <dc> <domain> <dc> A <ip> -Uadministrator
```
* If you're getting "tsig verify failure" for samba_dnsupdate in your logs, run this command manually on each of your controllers to set up the required DNS names for replication. It won't eliminate these errors but at least you can get replication working:
```
samba_dnsupdate --all-names --use-samba-tool
```
* If domain-join fails with "LDAP error 10 LDAP_REFERRAL" with stack trace, there are problably stale DNS records lingering on your existing domain controllers. Look for the FQDN in this error message (looks like ldap://abcdef-abc-xxx._msdcs.your.domain) and remove from ALL of your domain controllers:
```
for DC in dc1 dc2 dc3 etc; do
  samba-tool dns delete $DC _msdcs.<domain> abcdef-abc-xxx CNAME <host> -Uadministrator
done
```
* To fully clean out replication state for a secondary domain controller, shut it down, clear its /var/lib/samba/private volume contents, and while it's shut down do these on the primary:
```
samba-tool domain demote --remove-other-dead-server=<badhost>
samba-tool dbcheck --cross-ncs --fix
```
Then restart the secondary with `DOMAIN_ACTION=join`.
* With docker it's real easy to get a bunch of stale entries in your domain controller list. The latest version of samba4 provides a way to prune them:
{noformat}
samba-tool domain demote --remove-other-dead-server=xxx
{noformat}

### Contributing

If you want to make improvements to this image, see [CONTRIBUTING](https://github.com/instantlinux/docker-tools/blob/main/CONTRIBUTING.md).

[![](https://img.shields.io/badge/license-GPL--3.0-red.svg)](https://choosealicense.com/licenses/gpl-3.0/ "License badge") [![](https://img.shields.io/badge/code-samba_team%2Fsamba-blue.svg)](https://gitlab.com/samba-team/samba "Code repo")
