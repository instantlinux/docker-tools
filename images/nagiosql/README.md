## nagiosql

[![](https://images.microbadger.com/badges/version/instantlinux/nagiosql.svg)](https://microbadger.com/images/instantlinux/nagiosql "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/nagiosql.svg)](https://microbadger.com/images/instantlinux/nagiosql "Image badge") [![](https://images.microbadger.com/badges/commit/instantlinux/nagiosql.svg)](https://microbadger.com/images/instantlinux/nagiosql "Commit badge")

Web GUI for managing Nagios monitoring service.

### Usage

NagiosQL is a UI for managing host, service and related definitions for Nagios. In May 2018 it was finally updated to work with Nagios Core v4.x. Here in this codebase find an example [docker-compose.yml](https://github.com/instantlinux/docker-tools/blob/master/images/nagiosql/docker-compose.yml) which will launch 3 services: the jasonrivers/nagios image, this NagiosQL image and an nginx server which provides SSL termination.

Steps:
* Create a blank database (e.g. nagiosql) or a copy of your existing NagiosQL database on your MySQL server and assign its password in the docker secret identified in your docker-compose.yml (see example as noted above)
* Copy the [docker-compose.yml](https://github.com/instantlinux/docker-tools/blob/master/images/nagiosql/docker-compose.yml) from this repo and define any environment-var overrides you might need (as defined below)
* Bring up Nagios4 and NagiosQL using `docker-compose up`
* In a browser, connect to NagiosQL UI at the port number identified in docker-compose.yml, log in as nagiosadmin / nagios, enter the database install or update dialog
* Define hosts, services and other objects
* Under Tools -> Nagios control, invoke Write monitoring data, Write additional data, Check configuration files
* Restart nagios server if the configuration check passed

Tips:
* (To secure nagios itself) use htpasswd (provided in the jasonrivers image), add your administrative user(s) to htpasswd.users at top level in nagios_etc volume, and update cgi.cfg to include user name(s) in each of the authorized_xxx settings
* Nagios v4 requires that each service be attached to at least one host or hostgroups. If you're migrating from an old installation, deactivate any service definitions that are no longer in use

### Current Status

Alpha--the only known issue is the restart button doesn't work (a workaround is to invoke docker restart of the nagios container). Not verified under kubernetes (on the theory that fewer dependencies are better for the lowest-level monitoring system during any outage).

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

[![](https://images.microbadger.com/badges/license/instantlinux/nagiosql.svg)](https://microbadger.com/images/instantlinux/nagiosql "License badge") [![](https://img.shields.io/badge/code-sourceforge%2Fnagiosql-blue.svg)](https://sourceforge.net/projects/nagiosql/ "Code repo")
