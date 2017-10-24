## mythsuse
[![](https://images.microbadger.com/badges/version/instantlinux/mythsuse.svg)](https://microbadger.com/images/instantlinux/mythsuse "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/mythsuse.svg)](https://microbadger.com/images/instantlinux/mythsuse "Image badge") [![](https://images.microbadger.com/badges/commit/instantlinux/mythsuse.svg)](https://microbadger.com/images/instantlinux/mythsuse "Commit badge")

The MythTV backend built under OpenSuSE.

### Usage

This image must be run in network_mode:host in order to communicate with HD Homerun tuners; assign a new IP address and hostname for this application, and define it as a secondary IP address on your Docker host's primary interface.

For configuration, see the example docker-compose.yml. Set environment variables and secrets as defined here, then run "docker-compose up -d".

Reach mythtv-setup in the usual way; default password is mythtv:
~~~
docker exec mythtvbackend_app_1 /usr/sbin/sshd
ssh -p 2022 -X mythtv@<host-ip>
mythtv-setup
~~~
Change the password by generating a new hashed password and setting mythtv-user-password secret.

### Status

This image worked as of Sep 2017 but I've reluctantly given up on OpenSuSE after running MythTV on it since 2008. The core maintainers of MythTV use Ubuntu, and the PackMan repo for OpenSuSE has fallen increasingly behind with each new release. The current Docker image for Ubuntu is called mythtv-backend.

### Variables
Variable | Default | Description
-------- | ------- | -----------
APACHE_LOG_DIR | /var/log/apache2 | Apache logs
DBNAME | mythtv | Database name
DBSERVER | db00 | Database server hostname
LANG | en_US.UTF-8 | 
LANGUAGE | en_US.UTF-8 | 
TZ | UTC | Time zone

### Secrets
Secret | Description
------ | -----------
mythtv-db-password | Password of MythTV db user
mythtv-user-password | Hashed password of MythTV ssh user

[![](https://images.microbadger.com/badges/license/instantlinux/mythsuse.svg)](https://microbadger.com/images/instantlinux/mythsuse "License badge")
