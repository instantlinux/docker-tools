## rest-server
[![](https://img.shields.io/docker/v/instantlinux/rest-server?sort=date)](https://hub.docker.com/r/instantlinux/rest-server/tags "Version badge") [![](https://img.shields.io/docker/image-size/instantlinux/rest-server?sort=date)](https://github.com/instantlinux/docker-tools/tree/main/images/rest-server "Image badge") ![](https://img.shields.io/badge/platform-amd64%20arm64%20arm%2Fv6%20arm%2Fv7-blue "Platform badge") [![](https://img.shields.io/badge/dockerfile-latest-blue)](https://gitlab.com/instantlinux/docker-tools/-/blob/main/images/rest-server/Dockerfile "dockerfile") [![](https://img.shields.io/badge/ghcr-package-blue?logo=github "ghcr badge")](https://github.com/users/instantlinux/packages/container/package/rest-server)

Backend server for restic backup client.

### Usage

This example is for docker-compose.
Set up a secret:
```
USERNAME=bkp
SECRETS_DIR=/var/adm/secrets
htpasswd -B -c $SECRETS_DIR/restic-htpasswd $USERNAME
chgrp 2025 $SECRETS_DIR/restic-htpasswd
chmod 640 $SECRETS_DIR/restic-htpasswd
```
If using helm, convert the rest-htpasswd to base64 and:
```
cd docker-tools/k8s
make secrets/restic-htpasswd.yml
make secrets/restic-htpasswd
```

Define a storage volume on the host; create a blank volume and:
```
sudo mount /dev/<dev name> /var/backup/restic
sudo chown 2025 /var/backup/restic
sudo chmod 700 /var/backup/restic
```

An example compose file is provided here in docker-compose.yml. This is for the common scenario of running under docker-compose on a file server. Customize [Makefile](https://github.com/instantlinux/docker-tools/blob/main/services/Makefile) after cloning this repo:
~~~
git clone https://github.com/instantlinux/docker-tools.git
cd docker-tools/services
make rest-server
~~~

### Variables

These variables can be passed to the image from docker-compose.yml as needed:

Variable | Default | Description |
-------- | ------- | ----------- |
DATA_DIRECTORY | /data | Destination path to use within container
PASS_SECNAME | restic-htpasswd | Name of secret holding htpasswd file

Container UID is 2025.

### Volumes

Mount a host directory into the container:

Host Path | Container Path
/var/backup/restic | /data

### Secrets

Secret | Description
------ | -----------
ftp-user-password-secret | (optional) hashed pw of upload user

### Contributing

If you want to make improvements to this image, see [CONTRIBUTING](https://github.com/instantlinux/docker-tools/blob/main/CONTRIBUTING.md).

[![](https://img.shields.io/badge/license-Apache--2.0-red.svg)](https://choosealicense.com/licenses/apache-2.0/ "License badge") [![](https://img.shields.io/badge/code-restic%2Frest--server-blue.svg)](https://github.com/restic/rest-server "Code")
