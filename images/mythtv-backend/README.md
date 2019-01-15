## mythtv-backend
[![](https://images.microbadger.com/badges/version/instantlinux/mythtv-backend.svg)](https://microbadger.com/images/instantlinux/mythtv-backend "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/mythtv-backend.svg)](https://microbadger.com/images/instantlinux/mythtv-backend "Image badge") [![](https://images.microbadger.com/badges/commit/instantlinux/mythtv-backend.svg)](https://microbadger.com/images/instantlinux/mythtv-backend "Commit badge")

The MythTV backend built under Ubuntu 18.04 LTS.

### Usage

This image must be run in network_mode:host in order to communicate with HD Homerun tuners; assign a new IP address and hostname for this application, and define it as a secondary IP address on your Docker host's primary interface.

For configuration, see the example docker-compose.yml (for swarm or standalone docker) or kubernetes.yaml to run on bare-metal Kubernetes. Set environment variables and secrets as defined here, customize volume mounts as desired. This repo has complete instructions for
[building a kubernetes cluster](https://github.com/instantlinux/docker-tools/blob/master/k8s/README.md) where you can then deploy [kubernetes.yaml](https://github.com/instantlinux/docker-tools/blob/master/images/mythtv-backend/kubernetes.yaml) with the Makefile or:
~~~
cat kubernetes.yaml | envsubst | kubectl apply -f -
~~~

If you have two Kubernetes nodes set up, run the kubernetes-ha.yaml to set up data sync between two identical drives across the nodes, and define a floating IP address. One copy of mythbackend will be running on one of the nodes at any given time, providing a simple high-availability configuration. See more details in the Makefile in k8s directory.

You can also run this directly (without compose or kubernetes) using environment variables and secrets files.

Use -v options to map in the paths to your media. Here's an example, mapped a single folder into /dvr. Put the two secrets files into a protected directory and launch with:
~~~
docker run -d --name mythtv \
  --network=host \
  -e DBNAME='mythtv' \
  -e DBSERVER='<Your mysql server name or ip>' \
  -v <Your dvr/media storage path>:/dvr \
  -v <secrets path>/mythtv-db-password:/run/secrets/mythtv-db-password:ro \
  -v <secrets path>/mythtv-user-password:/run/secrets/mythtv-user-password:ro \
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
LANG | en_US.UTF-8 | 
LANGUAGE | en_US.UTF-8 | 
LOCALHOSTNAME | | Override if needed (see [config.xml](https://www.mythtv.org/wiki/Config.xml))
TZ | UTC | Time zone

### Secrets

Add these as Kubernetes secrets, or if you're running standalone specify these with source type "file". See the above volume mounts or the sample docker-compose.yml.

Secret | Description
------ | -----------
mythtv-db-password | Password of MythTV db user
mythtv-user-password | Hashed password of MythTV ssh user

[![](https://images.microbadger.com/badges/license/instantlinux/mythtv-backend.svg)](https://microbadger.com/images/instantlinux/mythtv-backend "License badge")
