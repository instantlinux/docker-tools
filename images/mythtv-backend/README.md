## mythtv-backend
[![](https://images.microbadger.com/badges/version/instantlinux/mythtv-backend.svg)](https://microbadger.com/images/instantlinux/mythtv-backend "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/mythtv-backend.svg)](https://microbadger.com/images/instantlinux/mythtv-backend "Image badge") [![](https://images.microbadger.com/badges/commit/instantlinux/mythtv-backend.svg)](https://microbadger.com/images/instantlinux/mythtv-backend "Commit badge")

The MythTV backend built under Ubuntu 18.04 LTS.

### Usage

This image must be run in network_mode:host in order to communicate with HD Homerun tuners; assign a new IP address and hostname for this application, and define it as a secondary IP address on your Docker host's primary interface.

For configuration, see the example docker-compose.yml (for swarm or standalone docker) or kubernetes.yaml to run on bare-metal Kubernetes. Set environment variables and secrets as defined here, customize volume mounts as desired, then run "docker-compose up -d" or "kubectl apply -f kubernetes.yaml".

If you have two Kubernetes nodes set up, run the kubernetes-ha.yaml to set up data sync between two identical drives across the nodes, and define a floating IP address. One copy of mythbackend will be running on one of the nodes at any given time, providing a simple high-availability configuration. See more details in the Makefile in k8s directory.

As an alterantive, this can be run directly using environment variables. The mythtv user password cannot be setup this way, but you shouldn't be running ssh after initial setup anyway.

Use -v options to map in the paths to your media. For my purposes, I've mapped a single folder into /dvr.
~~~
docker run -d --name mythtv \
--network=host \
-e DBNAME='mythtv' \
-e DBSERVER='<Your mysql server name or ip>' \
-e DBPASSWORD='<Password for Mythtv User>' \
-v <Your dvr/media storage path>:/dvr \
instantlinux/mythtv-backend:latest
~~~

Reach mythtv-setup in the usual way after starting sshd on port 2022; default password is mythtv:
~~~
docker exec mythtvbackend_app_1 /usr/sbin/sshd
ssh -p 2022 -X mythtv@<host-ip>
mythtv-setup
~~~

If you're performing setup from a multi monitor system, the fullscreen mythtv-setup might not be entirely visible. In this case, use the following to limit the resolution
~~~
mythtv-setup -w -geometry 1280x720
~~~

Change the password by generating a new hashed password and setting mythtv-user-password secret.

Look for MythTV status pages on port 6544, and MythWeb is serviced on 6760.

### Variables
Variable | Default | Description
-------- | ------- | -----------
APACHE_LOG_DIR | /var/log/apache2 | Apache logs
DBNAME | mythtv | Database name
DBSERVER | db00 | Database server hostname
DBPASSWORD |    | Database server password
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
