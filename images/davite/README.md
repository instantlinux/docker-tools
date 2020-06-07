## davite
[![](https://img.shields.io/docker/v/instantlinux/davite?sort=date)](https://microbadger.com/images/instantlinux/davite "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/davite.svg)](https://microbadger.com/images/instantlinux/davite "Image badge") [![](https://images.microbadger.com/badges/commit/instantlinux/davite.svg)](https://microbadger.com/images/instantlinux/davite "Commit badge")

DaVITE is an event-invitations server modeled after eVite, written in
2001 by David Madison. This image wraps it in a layer of the official
httpd Apache image.

### Usage
Set the variables as defined below, and run with docker-compose or
kubernetes. The service will be visible as
http://host/cgi-bin/DaVite.cgi. Create an invitation by entering your
email address; that will generate a URI which you can then use to edit
your event invitation.

This repo has complete instructions for
[building a kubernetes cluster](https://github.com/instantlinux/docker-tools/blob/master/k8s/README.md) where you can deploy [kubernetes.yaml](https://github.com/instantlinux/docker-tools/blob/master/images/davite/kubernetes.yaml) using _make_ and customizing [Makefile.vars](https://github.com/instantlinux/docker-tools/blob/master/k8s/Makefile.vars) after cloning this repo:
~~~
git clone https://github.com/instantlinux/docker-tools.git
cd docker-tools/k8s
make davite
~~~

### Variables

These variables can be passed to the image from kubernetes.yaml or docker-compose.yml as needed:

| Variable | Default | Description |
| -------- | ------- | ----------- |
| HOSTNAME | | External DNS name of DaVite service |
| SCHEME | http | Set to https if behind SSL proxy |
| SMTP_SMARTHOST | smtp | Outbound email relay hostname |
| SMTP_PORT | 587 | Port for sending emails (no auth) |
| TZ | UTC | time zone |

### Credits

DaVite is authored by David Madison who maintains links to the
original (long-deprecated) code at [marginalhacks](http://marginalhacks.com/Hacks/DaVite).

[![](https://images.microbadger.com/badges/license/instantlinux/davite)](https://microbadger.com/images/instantlinux/davite "License badge") [![](https://img.shields.io/badge/code-instantlinux%2Fdocker_tools-blue.svg)](https://github.com/instantlinux/docker-tools/tree/master/images/davite/src "Code repo")
