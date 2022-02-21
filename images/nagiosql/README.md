## nagiosql
[![](https://img.shields.io/docker/v/instantlinux/nagiosql?sort=date)](https://hub.docker.com/r/instantlinux/nagiosql/tags "Version badge") [![](https://img.shields.io/docker/image-size/instantlinux/nagiosql?sort=date)](https://github.com/instantlinux/docker-tools/-/blob/main/images/nagiosql "Image badge") ![](https://img.shields.io/badge/platform-amd64%20arm64%20arm%2Fv7-blue "Platform badge") [![](https://img.shields.io/badge/dockerfile-latest-blue)](https://gitlab.com/instantlinux/docker-tools/-/blob/main/images/nagiosql/Dockerfile "dockerfile")

Web GUI for managing Nagios monitoring service.

### Usage

NagiosQL is a UI for managing host, service and related definitions for Nagios. In May 2018 it was finally updated to work with Nagios Core v4.x. Here in this codebase find an example [docker-compose.yml](https://github.com/instantlinux/docker-tools/blob/main/images/nagiosql/docker-compose.yml) which will launch 3 services: the instantlinux/nagios image, this NagiosQL image and an nginx server which provides SSL termination.

Steps:
* Create a blank database (e.g. nagiosql) or a copy of your existing NagiosQL database on your MySQL server and assign its password in the docker secret identified in your docker-compose.yml (see example as noted above)
* Copy the [docker-compose.yml](https://github.com/instantlinux/docker-tools/blob/main/images/nagiosql/docker-compose.yml) from this repo and define any environment-var overrides you might need (as defined below)
* Specifically, check the environment variable NAGIOS_ETC to confirm it matches your nagios installation. The jasonrivers/nagios image used the Ubuntu location /opt/nagios/etc. The instantlinux/nagios alpine image needs NAGIOS_ETC=/etc/nagios.
* Bring up Nagios4 and NagiosQL using `docker-compose up`
* In a browser, connect to NagiosQL UI at the port number identified in docker-compose.yml, log in as nagiosadmin / nagios, enter the database install or update dialog
* Define hosts, services and other objects
* Under Tools -> Nagios control, invoke Write monitoring data, Write additional data, Check configuration files
* If the config check didn't find binary, set it under Administration -> Config targets -> Local installation -> edit. Look for Nagios binary file and set the value to `/usr/sbin/nagios`; fill in any other missing values, then Save
* Restart nagios server if the configuration check passed (using docker restart, the button doesn't work)
* If nagios server won't start due to configuration-check failures, manually lean up extraneous files and cfg_file entries from nagios.cfg. Known problems include localhost.cfg and windows.cfg.

Tips:
* (To secure nagios itself) use htpasswd, add your administrative user(s) to htpasswd.users at top level in /etc/nagios volume, and update cgi.cfg to include user name(s) in each of the authorized_xxx settings (see the AUTHORIZED_USERS setting if using instantlinux/nagios image)
* Nagios v4 requires that each service be attached to at least one host or hostgroups. If you're migrating from an old installation, deactivate any service definitions that are no longer in use

### Current Status

Stable -- with caveat that restart button doesn't work. You'll need to invoke restart from nagios itself, or from kubernetes/docker, after writing new configuration files.

### Variables

Variable | Default | Description |
-------- | ------- | ----------- |
ADMIN_PATH | /opt | Path on localhost to store etc files
DB_HOST | db00 | MySQL database hostname
DB_NAME | nagiosql | database name
DB_PORT | 3306 | TCP port number
DB_USER | nagiosql | database username
DB_PASSWD_SECRET | nagiosql-db-password | name of secret
DOMAIN | | used in docker-compose.yml by the nagios server
NAGIOS_ETC | /opt/nagios/etc | volume mountpoint for nagios.cfg
NAGIOS_MAIL_RELAY | smtp | DNS name for nagios email sending
PORT_NAGIOSQL| 8080 | Port to use for NagiosQL UI
REGISTRY_URI | (docker hub) | Local image registry
SHARE_PATH | /opt | Path on localhost to store SSL certs
TZ | UTC | local timezone

### Secrets

Secret | Description
------ | -----------
nagiosql-db-password | database credential
\<hostname>-server-key.pem | SSL cert (if using docker-compose)

### Contributing

If you want to make improvements to this image, see [CONTRIBUTING](https://github.com/instantlinux/docker-tools/blob/main/CONTRIBUTING.md).

[![](https://img.shields.io/badge/license-Apache--2.0-red.svg)](https://choosealicense.com/licenses/apache-2.0/ "License badge") [![](https://img.shields.io/badge/code-sourceforge%2Fnagiosql-blue.svg)](https://sourceforge.net/projects/nagiosql/ "Code repo")
