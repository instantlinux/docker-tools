## wxcam-upload
[![](https://img.shields.io/docker/v/instantlinux/wxcam-upload?sort=date)](https://hub.docker.com/r/instantlinux/wxcam-upload/tags "Version badge") [![](https://img.shields.io/docker/image-size/instantlinux/wxcam-upload?sort=date)](https://github.com/instantlinux/docker-tools/-/blob/main/images/wxcam-upload "Image badge") ![](https://img.shields.io/badge/platform-amd64%20arm64%20arm%2Fv6%20arm%2Fv7-blue "Platform badge") [![](https://img.shields.io/badge/dockerfile-latest-blue)](https://gitlab.com/instantlinux/docker-tools/-/blob/main/images/wxcam-upload/Dockerfile "dockerfile")

This wraps an upload script along with proftpd for publishing still images from network-attached webcams to the Weather Underground webcam server.

### Status

DEPRECATED - IBM discontinued webcam for Wunderground Oct 2021.

### Usage

Sign up with Weather Underground to get a user login, and set up one or more webcams. Add secrets to your Docker Swarm installation (or define them as plain-text files), and set parameters as defined below. An example compose file is provided here in docker-compose.yml. This repo has complete instructions for
[building a kubernetes cluster](https://github.com/instantlinux/docker-tools/blob/main/k8s/README.md) where you can launch with [helm](https://github.com/instantlinux/docker-tools/tree/main/images/wxcam-upload/helm) or [kubernetes.yaml](https://github.com/instantlinux/docker-tools/blob/main/images/wxcam-upload/kubernetes.yaml) using _make_ and customizing [Makefile.vars](https://github.com/instantlinux/docker-tools/blob/main/k8s/Makefile.vars) after cloning this repo:
~~~
git clone https://github.com/instantlinux/docker-tools.git
cd docker-tools/k8s
make wxcam-upload
~~~

### Variables

This image is based on instantantlinux/proftpd; see the variables there as well as these.

Variable | Default | Description |
-------- | ------- | ----------- |
ANONYMOUS_DISABLE | on | no downloads from local ftp
CAMS | cam1 | names of webcams (space-delimited list)
INTERVAL | 5 | interval for transmitting to Weather Underground (minutes)
PASV_MAX_PORT | 30090 | docker-host port number range
PASV_MIN_PORT | 30081 |
UPLOAD_HOSTNAME | webcam.wunderground.com | destination of image uploads
UPLOAD_PASSWORD_SECRET | wunderground-user-password | name of secret for API
UPLOAD_PATH | /home/wx/upload | root of uploaded files
UPLOAD_USERNAME | required | Weather Underground API user
WXUSER_NAME | wx | username for wx upload
WXUSER_PASSWORD_SECRET | wxuser-password-hashed | name of secret for ftp user
WXUSER_UID | 2060 | uid of wx files
TZ | UTC | timezone

### Secrets

Secret | Description
------ | -----------
wunderground-user-password | password for Weather Underground ftp server
wunderground-pw-cam | if you have more than one, use multiple entries
wxcam-password-hashed | hashed password of 
wxuser-password-hashed | hashed password of ftp upload user

[![](https://images.microbadger.com/badges/license/instantlinux/wxcam-upload)](https://microbadger.com/images/instantlinux/wxcam-upload "License badge") [![](https://img.shields.io/badge/code-proftpd%2Fproftpd-blue.svg)](https://github.com/proftpd/proftpd "Code repo") [![](https://img.shields.io/badge/code-nftpd_com%2Fclient-blue.svg)](http://www.ncftpd.com/download "Code repo")
