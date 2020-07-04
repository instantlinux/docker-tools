## duplicati

[![](https://img.shields.io/docker/v/instantlinux/duplicati?sort=date)](https://microbadger.com/images/instantlinux/duplicati "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/duplicati.svg)](https://microbadger.com/images/instantlinux/duplicati "Image badge") [![](https://images.microbadger.com/badges/commit/instantlinux/duplicati.svg)](https://microbadger.com/images/instantlinux/duplicati "Commit badge")

Duplicati 2.0 software for secure online/local backups. After CrashPlan discontinued its individual-user subscription service in 2018, this along with the BackBlaze B2 or Amazon S3 service is the most-active open-source project and is the best alternative for Linux users. Project organizers tag releases "beta", "experimental", and "canary"; to take advantage of the rapid pace of development, this container image provides the experimental release which has the most-current reasonably-stable feature set. Use the linuxserver/duplicati:latest image if you wish to run the older beta version. This one includes timezone support.

### Usage

In your kubernetes.yaml or docker-compose file, add the list of volumes you wish to back up under /backup. If you're backing up a server, set the PUID environment value to root user (0), otherwise set it to any user-id that has read access to your files. Bring up the stack and define backup configurations; see [software documentation](https://github.com/duplicati/duplicati/wiki). All other configuration is done via the UI on TCP port 8200.

Example kubernetes.yaml and docker-compose.yml files are provided here. This repo has complete instructions for
[building a kubernetes cluster](https://github.com/instantlinux/docker-tools/blob/master/k8s/README.md) where you can deploy [kubernetes.yaml](https://github.com/instantlinux/docker-tools/blob/master/images/duplicati/kubernetes.yaml) using _make_ and customizing [Makefile.vars](https://github.com/instantlinux/docker-tools/blob/master/k8s/Makefile.vars) after cloning this repo:
~~~
git clone https://github.com/instantlinux/docker-tools.git
cd docker-tools/k8s
make duplicati
~~~

### Variables

Variable | Default | Description
-------- | ------- | -----------
PGID | 34 | Group ID for backup user
PUID | 34 | User ID
TZ | UTC | time zone

[![](https://img.shields.io/badge/license-LGPL--2.1-red.svg)](https://choosealicense.com/licenses/lgpl-2.1/ "License badge") [![](https://img.shields.io/badge/code-duplicati%2Fduplicati-blue.svg)](https://github.com/duplicati/duplicati "Code repo")
