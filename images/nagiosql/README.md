## nagiosql

[![](https://images.microbadger.com/badges/version/instantlinux/nagiosql.svg)](https://microbadger.com/images/instantlinux/nagiosql "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/nagiosql.svg)](https://microbadger.com/images/instantlinux/nagiosql "Image badge") [![](https://images.microbadger.com/badges/commit/instantlinux/nagiosql.svg)](https://microbadger.com/images/instantlinux/nagiosql "Commit badge")

Web GUI for managing Nagios monitoring service.

### Usage

NagiosQL is a UI for managing host, service and related definitions for Nagios. In May 2018 it was finally updated to work with Nagios Core v4.x. Here in this codebase find an example [docker-compose.yml](https://github.com/instantlinux/docker-tools/blob/master/images/nagiosql/docker-compose.yml) which will launch 3 services: the jasonrivers/nagios image, this NagiosQL image and an nginx server which provides SSL termination.

Steps:
* Create a blank database (e.g. nagiosql) or a copy of your existing NagiosQL database on your MySQL server and assign its password in the docker secret identified in your docker-compose.yml (see example as noted above)
* Bring up the NagiosQL UI at the port number identified in docker-compose.yml, log in as nagiosadmin / nagios, enter the database install or update dialog
* Define hosts, services and other objects
* Under Tools -> Nagios control, invoke Write monitoring data, Write additional data, Check configuration files
* Restart nagios server if the configuration check passed

Tips:
* (To secure nagios itself) use htpasswd (provided in the jasonrivers image), add your administrative user(s) to htpasswd.users at top level in nagios_etc volume, and update cgi.cfg to include user name(s) in each of the authorized_xxx settings
* Nagios v4 requires that each service be attached to at least one host or hostgroups. If you're migrating from an old installation, deactivate any service definitions that are no longer in use

### Current Status

Alpha--the only known issue is the restart button doesn't work (a workaround is to invoke docker restart of the nagios container).

### Variables

Variable | Default | Description |
-------- | ------- | ----------- |
DB_HOST | db00 | MySQL database hostname
DB_NAME | nagiosql | database name
DB_PORT | 3306 | TCP port number
DB_USER | nagiosql | database username
DB_PASSWD_SECRET | nagiosql-db-password | name of secret
TZ | UTC | local timezone

### Secrets

Secret | Description
------ | -----------
nagiosql-db-password | database credential
<hostname>-server-key.pem | SSL cert private key

[![](https://images.microbadger.com/badges/license/instantlinux/nagiosql.svg)](https://microbadger.com/images/instantlinux/nagiosql "License badge")
