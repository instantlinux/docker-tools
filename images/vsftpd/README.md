## vsftpd
[![](https://img.shields.io/docker/v/instantlinux/vsftpd?sort=date)](https://hub.docker.com/r/instantlinux/vsftpd/tags "Version badge") [![](https://img.shields.io/docker/image-size/instantlinux/vsftpd?sort=date)](https://github.com/instantlinux/docker-tools/-/blob/main/images/vsftpd "Image badge") ![](https://img.shields.io/badge/platform-amd64%20arm64%20arm%2Fv6%20arm%2Fv7-blue "Platform badge") [![](https://img.shields.io/badge/dockerfile-latest-blue)](https://gitlab.com/instantlinux/docker-tools/-/blob/main/images/vsftpd/Dockerfile "dockerfile")

A clean, easy-to-use, tiny yet full-featured installation of vsftpd wrapped in Alpine.

### Usage

*Status: DEPRECATED*

The most-common directives can be specified in environment variables as shown below. If you need further customizations, put them in one or more files under a mount point /etc/vsftpd.d.

A single upload user can be specified via the FTPUSER_xxx variables. It is activated by defining ftp-user-password-secret thus:

    python -c "import crypt,random,string; \
      print crypt.crypt('YOURPASSWORD', '\$6\$' + ''.join( \
	[random.choice(string.ascii_letters + string.digits) \
      for _ in range(16)]))" | \
    docker secret create ftp-user-password-secret -

An example compose file is provided here in docker-compose.yml. This is for the common scenario of sharing from Docker swarm the contents of a network-attached volume as a read-only anonymous-ftp service. This repo has complete instructions for
[building a kubernetes cluster](https://github.com/instantlinux/docker-tools/blob/main/k8s/README.md) where you can deploy [kubernetes.yaml](https://github.com/instantlinux/docker-tools/blob/main/images/vsftpd/kubernetes.yaml) using _make_ and customizing [Makefile.vars](https://github.com/instantlinux/docker-tools/blob/main/k8s/Makefile.vars) after cloning this repo:
~~~
git clone https://github.com/instantlinux/docker-tools.git
cd docker-tools/k8s
make vsftpd
~~~

Status: There's a recent fix for segfault crashes with vsftpd version 3.0.3 under Alpine that will come out in a future version. This one has a workaround that may work for you. [Wikipedia|https://en.wikipedia.org/wiki/Vsftpd] has a brief history of how vsftpd met its demise after 2011. I've switched to proftpd (see that image).

### Variables

These variables can be passed to the image from kubernetes.yaml or docker-compose.yml as needed:

Variable | Default | Description |
-------- | ------- | ----------- |
ANONYMOUS_ENABLE | YES | Anonymous login
ANON_MKDIR_WRITE_ENABLE | NO | Anonymous mkdir
ANON_UPLOAD_ENABLE | NO | Anonymous upload
FTPUSER_PASSWORD_SECRET | ftp-user-password-secret | hashed pw of upload user
FTPUSER_NAME | ftpuser | upload username
FTPUSER_UID | 1001 | upload file ownership UID
LOCAL_UMASK | 022 | upload umask
LOG_FTP_PROTOCOL | NO | more-verbose logging
PASV_ADDRESS |  | required--address of docker engine
PASV_MAX_PORT | 30100 | range of client ports (rebuild image if changed)
PASV_MIN_PORT | 30091 | 
TZ | UTC | local timezone
USE_LOCALTIME | YES | local time for directory listing
VSFTPD_LOG_FILE | /dev/stdout | logfile destination
WRITE_ENABLE | YES | allow put/rm

### Secrets

Secret | Description
------ | -----------
ftp-user-password-secret | (optional) hashed pw of upload user

### Contributing

If you want to make improvements to this image, see [CONTRIBUTING](https://github.com/instantlinux/docker-tools/blob/main/CONTRIBUTING.md).

[![](https://img.shields.io/badge/license-Apache--2.0-red.svg)](https://choosealicense.com/licenses/apache-2.0/ "License badge") [![](https://img.shields.io/badge/code-ubuntu%2Fvsftpd-blue.svg)](https://launchpad.net/ubuntu/+source/vsftpd "Code")
