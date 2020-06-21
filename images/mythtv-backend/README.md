## mythtv-backend
[![](https://img.shields.io/docker/v/instantlinux/mythtv-backend?sort=date)](https://microbadger.com/images/instantlinux/mythtv-backend "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/mythtv-backend.svg)](https://microbadger.com/images/instantlinux/mythtv-backend "Image badge") ![](https://img.shields.io/badge/platform-amd64-blue "Platform badge") [![](https://img.shields.io/badge/dockerfile-latest-blue)](https://gitlab.com/instantlinux/docker-tools/-/blob/master/images/mythtv-backend/Dockerfile "dockerfile")

The MythTV backend built under Ubuntu Focal Fossa.

### Usage

This image must be run in network_mode:host in order to communicate with HD Homerun tuners; assign a new IP address and hostname for this application, and define it as a secondary IP address on your Docker host's primary interface.

For configuration, see the example docker-compose.yml (for swarm or standalone docker) or kubernetes.yaml to run on bare-metal Kubernetes. Set environment variables and secrets as defined here, customize volume mounts as desired. This repo has complete instructions for
[building a kubernetes cluster](https://github.com/instantlinux/docker-tools/blob/master/k8s/README.md) where you can then deploy [kubernetes.yaml](https://github.com/instantlinux/docker-tools/blob/master/images/mythtv-backend/kubernetes.yaml) using _make_ and customizing [Makefile.vars](https://github.com/instantlinux/docker-tools/blob/master/k8s/Makefile.vars) after cloning this repo:
~~~
git clone https://github.com/instantlinux/docker-tools.git
cd docker-tools/k8s
make mythtv-backend
~~~

If you have two Kubernetes nodes set up, run the kubernetes-ha.yaml to set up data sync between two identical drives across the nodes, and define a floating IP address. One copy of mythbackend will be running on one of the nodes at any given time, providing a simple high-availability configuration. See more details in the Makefile in k8s directory. The kubernetes.yaml sample provided here can also set up the mythweb virtual-host https://mythweb.yourdomain.com so you can schedule recordings when you're not home; create an htpasswd file with name _auth_ and then:
~~~
kubectl create secret generic mythweb-auth --from-file=auth
~~~

You can also run this image directly (without compose or kubernetes) using environment variables and secrets files.

Use -v options to map in the paths to your media. Here's an example, mapped a single folder into /dvr. Put the secrets files into a protected directory and launch with:
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

### MythTV Frontend

To build your frontends, use any installer you prefer. This repo provides one powered by ansible. To use it, on your frontend do a base install of Ubuntu LTS (20.04 is not yet working, at least not for Intel graphics), choose your frontend host DNS name(s), clone this repo and then invoke the ansible script:
```
cd ansible
cat <<EOT >>hosts
[mythfrontends]
frontend.your.hostdomain
EOT
make mythfrontend-setup
```

This ansible script is prone to configuration glitches so you will likely have to make adjustments in order to complete the process.

### Secrets

Add these as Kubernetes secrets, or if you're running standalone specify these with source type "file". See the above volume mounts or the sample docker-compose.yml.

Secret | Description
------ | -----------
mythtv-db-password | Password of MythTV db user
mythtv-user-password | Hashed password of MythTV ssh user
mythweb-auth | htpasswd for mythweb user(s) under k8s

[![](https://images.microbadger.com/badges/license/instantlinux/mythtv-backend)](https://microbadger.com/images/instantlinux/mythtv-backend "License badge") [![](https://img.shields.io/badge/code-mythtv%2Fmythtv-blue.svg)](https://github.com/mythtv/mythtv "Code repo")
