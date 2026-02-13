## mythtv-backend
[![](https://img.shields.io/docker/v/instantlinux/mythtv-backend?sort=date)](https://hub.docker.com/r/instantlinux/mythtv-backend/tags "Version badge") [![](https://img.shields.io/docker/image-size/instantlinux/mythtv-backend?sort=date)](https://github.com/instantlinux/docker-tools/tree/main/images/mythtv-backend "Image badge") ![](https://img.shields.io/badge/platform-amd64-blue "Platform badge") [![](https://img.shields.io/badge/dockerfile-latest-blue)](https://gitlab.com/instantlinux/docker-tools/-/blob/main/images/mythtv-backend/Dockerfile "dockerfile")

The MythTV backend built under Ubuntu noble (24.04).

### Usage

This image must be run in network_mode:host in order to communicate with HD Homerun tuners; assign a new IP address and hostname for this application, and define it as a secondary IP address on your Docker host's primary interface.

For configuration, see the example docker-compose.yml (for swarm or standalone docker) or [helm](https://github.com/instantlinux/docker-tools/blob/main/images/helm). Set variables and secrets as defined here, and customize volume mounts as desired. This repo has complete instructions for
[building a kubernetes cluster](https://github.com/instantlinux/docker-tools/blob/main/k8s/README.md) where you can launch with [helm](https://github.com/instantlinux/docker-tools/tree/main/images/mythtv-backend/helm) using _make_ and customizing [Makefile.vars](https://github.com/instantlinux/docker-tools/blob/main/k8s/Makefile.vars) after cloning this repo:
~~~
git clone https://github.com/instantlinux/docker-tools.git
cd docker-tools/k8s
make mythtv-backend
~~~

If you have two Kubernetes nodes set up, run the kubernetes-ha.yaml to set up data sync between two identical drives across the nodes, and define a floating IP address. One copy of mythbackend will be running on one of the nodes at any given time, providing a simple high-availability configuration. See more details in the Makefile in k8s directory. The kubernetes.yaml sample provided here can also set up the mythweb virtual-host https://mythweb.yourdomain.com so you can schedule recordings when you're not home.

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

Change the password by generating a new hashed password and setting mythtv-user-password secret.

Look for MythTV status pages and configuration UI on port 6544.

Starting with v34, mythtv-setup is accessed via <pod-ip>:6544/setupwizard. Use that to define video sources, storage groups, and set up channels.

### Variables
Variable | Default | Description
-------- | ------- | -----------
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

Note that the [Kodi](https://kodi.tv/download/) frontend also provides limited support for the MythTV backend.
 
### Volumes

Optionally, mount this path name to persistent storage:

Path | Description
---- | -----------
/etc/ssh | Host keys and configs for ssh

### Secrets

Add these as Kubernetes secrets, or if you're running standalone specify these with source type "file". See the above volume mounts or the sample docker-compose.yml.

Secret | Description
------ | -----------
mythtv-db-password | Password of MythTV db user
mythtv-user-password | Hashed password of MythTV ssh user

### Upgrade Notes

When upgrading to 36.0, the setup wizard is served on port 6544 without any auth protection. In upstream [MythTV issue #1077](https://github.com/MythTV/mythtv/issues/1077), I asked for a way to protect this sensitive management console in order to schedule recordings while away from home. As of Feb 2026, the [documentation](https://wiki.mythtv.org/wiki/Web_Application#API_and_Web_App_Authentication) states that upon this upgrade, it "comes with the admin user preinstalled". I couldn't login, but I could invoke _Settings -> Users -> New User_ to add the user `admin` with a password of my own choosing, and could then use admin to activate _Authentication Required for All IP Addresses_ user setting.

(Below may apply only if you're running version 30, from 2020 or earlier.)

You probably need to configure XMLTV in place of the old mythfilldatabase method used to fetch listings from [Schedules Direct](https://www.schedulesdirect.org/). See the documentation [Setup Video Sources](https://www.mythtv.org/wiki/Setup_Video_Sources). This image includes the required packages but does not automate setup. It's beyond scope of this document to describe the process fully but here are some of the required steps:

* Go into dashboard setup wizard, find your video source(s) and change the listings grabber to the new Schedules Direct xmltv setting for your location; make note of the video source name you're using and set a variable FILENAME to match 
* Invoke a channel-scan
* Have your Schedules Direct username and password ready and invoke from a command shell inside the container:
```
su - mythtv
tv_find_grabbers
  # (note which one corresponds to the video source)
tv_grab_na_dd --configure --config-file ~mythtv/.mythtv/${FILENAME}.xmltv
  # (enter username/password)
  # (select all channels)
```
* As user mythtv, invoke mythfilldatabase; you'll probably encounter a number of warnings about unknown xmltv channel identifier -- suppress those by changing the text `channel:` to `not channel:` in any line of this ${FILENAME} for which you don't have a valid channel entry (as viewed in the channel list in any of these places - mythweb UI, mythtfrontend listings screen, or SELECT from database's channel table). This is because the listings service includes many channels that your channel scan won't pick up, and the `tv_grab` utility insists on re-writing its config file upon each run, with the entire list it fetched from the listings service.

### Contributing

If you want to make improvements to this image, see [CONTRIBUTING](https://github.com/instantlinux/docker-tools/blob/main/CONTRIBUTING.md).

[![](https://img.shields.io/badge/license-GPL--2.0-red.svg)](https://choosealicense.com/licenses/gpl-2.0/ "License badge") [![](https://img.shields.io/badge/code-mythtv%2Fmythtv-blue.svg)](https://github.com/mythtv/mythtv "Code repo")
