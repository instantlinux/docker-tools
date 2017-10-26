## mythtv-backend
[![](https://images.microbadger.com/badges/version/instantlinux/mythtv-backend.svg)](https://microbadger.com/images/instantlinux/mythtv-backend "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/mythtv-backend.svg)](https://microbadger.com/images/instantlinux/mythtv-backend "Image badge") [![](https://images.microbadger.com/badges/commit/instantlinux/mythtv-backend.svg)](https://microbadger.com/images/instantlinux/mythtv-backend "Commit badge")

The MythTV backend built under Ubuntu 16.04 LTS.

### Usage

This image must be run in network_mode:host in order to communicate with HD Homerun tuners; assign a new IP address and hostname for this application, and define it as a secondary IP address on your Docker host's primary interface.

For configuration, see the example docker-compose.yml. Set environment variables and secrets as defined here, then run "docker-compose up -d".

Reach mythtv-setup in the usual way after starting sshd on port 2022; default password is mythtv:
~~~
docker exec mythtvbackend_app_1 /usr/sbin/sshd
ssh -p 2022 -X mythtv@<host-ip>
mythtv-setup
~~~
Change the password by generating a new hashed password and setting mythtv-user-password secret.

Look for MythTV status pages on port 6544, and MythWeb is serviced on 6760.

### Variables
Variable | Default | Description
-------- | ------- | -----------
APACHE_LOG_DIR | /var/log/apache2 | Apache logs
DBNAME | mythtv | Database name
DBSERVER | db00 | Database server hostname
LANG | en_US.UTF-8 | 
LANGUAGE | en_US.UTF-8 | 
LOCALHOSTNAME | | Override if needed (see [config.xml](https://www.mythtv.org/wiki/Config.xml))
TZ | UTC | Time zone

### Secrets

Because this (most likely) won't be running in swarm mode, specify these with source type "file". See the example docker-compose.yml.

Secret | Description
------ | -----------
mythtv-db-password | Password of MythTV db user
mythtv-user-password | Hashed password of MythTV ssh user

[![](https://images.microbadger.com/badges/license/instantlinux/mythtv-backend.svg)](https://microbadger.com/images/instantlinux/mythtv-backend "License badge")
