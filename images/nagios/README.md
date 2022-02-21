## nagios
[![](https://img.shields.io/docker/v/instantlinux/nagios?sort=date)](https://hub.docker.com/r/instantlinux/nagios/tags "Version badge") [![](https://img.shields.io/docker/image-size/instantlinux/nagios?sort=date)](https://github.com/instantlinux/docker-tools/-/blob/main/images/nagios "Image badge") ![](https://img.shields.io/badge/platform-amd64%20arm64%20arm%2Fv6%20arm%2Fv7-blue "Platform badge") [![](https://img.shields.io/badge/dockerfile-latest-blue)](https://gitlab.com/instantlinux/docker-tools/-/blob/main/images/nagios/Dockerfile "dockerfile")

Nagios Core monitoring service built under Alpine for multiple platforms

### Usage

This is Nagios Core 4.x and the primary plugins, served by nginx in an efficient Alpine image. It exists mainly because the jasonrivers/nagios image hasn't been maintained regularly since about 2018; this one is simpler, easier to keep up-to-date, handles restart properly and runs on your choice of platform. The new version of plugins has quite a few additions and improvements since then. Here in this codebase find an example [docker-compose.yml](https://github.com/instantlinux/docker-tools/blob/main/images/nagiosql/docker-compose.yml) which will launch 3 services: this instantlinux/nagios image, the [NagiosQL image](https://hub.docker.com/repository/docker/instantlinux/nagiosql) and another nginx server which provides SSL termination. To round out the monitoring solution, this setup is compatible with the free [easyNag](https://www.easynag.com/) mobile app.

To support plugins that you might want to add as a volume-mount, the image includes bash, the mariadb client, perl, python3, samba client, and sudo.

Steps:
* Set up NagiosQL as defined in its [README](https://github.com/instantlinux/docker-tools/blob/main/images/nagiosql), or import your existing Nagios configuration to a mountable volume.
* Copy the [docker-compose.yml](https://github.com/instantlinux/docker-tools/blob/main/images/nagiosql/docker-compose.yml) from this repo and define any environment-var overrides you might need (as defined below)
* Set up the nagios-htpasswd secret for basic-auth using the htpasswd command and place it in /var/adm/secrets/nagios-htpasswd
* Bring up Nagios4 and NagiosQL using `docker-compose up`

This will generate a nagios.cfg.proto; it will be copied to /etc/nagios/nagios.cfg only the first time the volume is mounted, after which you will have to edit it manually.

Note: if using NagiosQL for the first time, manual edits of nagios.cfg plus cleaning up distributed files (e.g. printer.cfg, windows.cfg) will most likely be required before nagios configuration check passes.

This will run under docker-compose or kubernetes using the bridge network; if you need to use certain plugins like check_dhcp which require direct host network, use the NGINX_PORT parameter to override the default port 80 to specify port (or ip:port if desired).

This repo has complete instructions for
[building a kubernetes cluster](https://github.com/instantlinux/docker-tools/blob/main/k8s/README.md) where you can deploy [kubernetes.yaml](https://github.com/instantlinux/docker-tools/blob/main/images/nagios/kubernetes.yaml) using _make_ and customizing [Makefile.vars](https://github.com/instantlinux/docker-tools/blob/main/k8s/Makefile.vars) after cloning this repo:
~~~
git clone https://github.com/instantlinux/docker-tools.git
cd docker-tools/k8s
make nagios
~~~

Tips:
* Nagios v4 requires that each service be attached to at least one host or hostgroups. If you're migrating from an old installation, deactivate any service definitions that are no longer in use

### Variables

Variable | Default | Description |
-------- | ------- | ----------- |
ADMIN_PATH | /opt | Path on localhost (for adding local plugins, etc)
AUTHORIZED_USERS | nagiosadmin | List of users
CONFIG_CHECK | yes | Whether to halt on startup if config-check fails
HTPASSWD_SECRET | nagios-htpasswd | Secret holding basic-auth user/passwords
MAIL_AUTH_USER | | Auth for SMTP relay provider
MAIL_AUTH_SECRET | nagios-mail-secret | Name of secret containing mail password
MAIL_RELAY_HOST | smtp:25 | FQDN and port of SMTP relay
MAIL_USE_TLS | yes | Whether to encrypt with TLS and STARTTLS
NAGIOS_MAIL_RELAY | smtp | DNS name for nagios email sending
NAGIOS_FQDN | nagios.docker | server_name for nginx
NGINX_PORT | 80 | listen port (or ip:port) for nginx
PERF_ENABLE | yes | Whether to generate performance logs
TZ | UTC | local timezone

### Volumes

Mount these path names to persistent storage:

Path | Description
---- | -----------
/etc/nagios | Configuration, as managed by NagiosQL
/opt/nagios/plugins | Any custom ($USER2$) plugins you want to add
/var/nagios | Logs and status

Some other important path names are:

Path | Description
---- | -----------
/usr/lib/nagios/plugins | System plugins ($USER1$)

### Secrets

Secret | Description
------ | -----------
nagios-htpasswd | Web UI basic-auth passwords
nagios-mail-secret | Auth secret for smtp provider

### Migrating from jasonrivers/nagios

This is almost-but-not-quite compatible (minus nagiosgraph) with the jasonriver/nagios image previously used by the services here. Here's what you need to know if you want to use this in place of that image:

- Since this is based on alpine rather than ubuntu, before starting this image look for your nagios.cfg and do these replacements in that and cgi.cfg:
```
sed -i -e 's:/opt/nagios/etc:/etc/nagios:' \
    -e 's:/opt/nagios/var:/var/nagios:' nagios.cfg
sed -i -e 's:/opt/nagios/etc:/etc/nagios:' cgi.cfg
```
- Update value of $USER1$ in resource.cfg:
```
sed -i -e 's:/opt/nagios/libexec:/usr/lib/nagios/plugins:' resource.cfg
```
- Set the environment variable NAGIOS_ETC to the new pathname /etc/nagios in your docker-compose or kubernetes container startup
- Change volume mounts to /etc/nagios and /var/nagios

### Contributing

If you want to make improvements to this image, see [CONTRIBUTING](https://github.com/instantlinux/docker-tools/blob/main/CONTRIBUTING.md).

If you want nagiosgraph or other features added, please [submit an issue](https://github.com/instantlinux/docker-tools/issues) with suggestions on implementation.

[![](https://img.shields.io/badge/license-GPL--2.0-red.svg)](https://choosealicense.com/licenses/gpl-2.0/ "License badge") [![](https://img.shields.io/badge/code-NagiosEnterprises%2Fnagioscore-blue.svg)](https://github.com/NagiosEnterprises/nagioscore)
