## git-dump
[![](https://img.shields.io/docker/v/instantlinux/git-dump?sort=date)](https://hub.docker.com/r/instantlinux/git-dump/tags "Version badge") [![](https://img.shields.io/docker/image-size/instantlinux/git-dump?sort=date)](https://github.com/instantlinux/docker-tools/-/blob/main/images/git-dump "Image badge") ![](https://img.shields.io/badge/platform-amd64%20arm64%20arm%2Fv6%20arm%2Fv7-blue "Platform badge") [![](https://img.shields.io/badge/dockerfile-latest-blue)](https://gitlab.com/instantlinux/docker-tools/-/blob/main/images/git-dump/Dockerfile "dockerfile")

This dockerizes a simple script I wrote years ago to create git bundle
backups of a private git server.

The example helm / docker-compose service definition will cause
a dump of all accessible projects to happen at the default hour
(0:45am in $TZ) from a GitLab server named git.instantlinux.net onto a
subdirectory git in volume "backup".

### Usage

Retention is set by a variable KEEP_DAYS which defaults to 31. Within
the DEST_DIR you will then find a separate directory for each day of
the month. If you set KEEP_DAYS to 7, it will keep a directory for
each day of the week. Backups older than KEEP_DAYS will be
automatically removed.

Provide a read-only private ssh key to access your git repo(s) in the
Docker secret git-dump_sshkey. Github has an apparently-permanent and
seemingly-arbitrary restriction against using the same read-only
deploy key for more than one repo, so unless you specify the https
access method, you will need to set up multiple instances of this
container to backup more than one Github repo.

For GitLab, Bitbucket or other private repos, you can use this to
back up an arbitrary number of git repos which share the same deploy
key. This script supports the GitLab v3 API to read the list of
projects at runtime, so you don't have to specify the REPOS parameter.

This repo has complete instructions for
[building a kubernetes cluster](https://github.com/instantlinux/docker-tools/blob/main/k8s/README.md) where you can deploy with helm or [kubernetes.yaml](https://github.com/instantlinux/docker-tools/blob/main/images/git-dump/kubernetes.yaml) using _make_ and customizing [Makefile.vars](https://github.com/instantlinux/docker-tools/blob/main/k8s/Makefile.vars) after cloning this repo:
~~~
git clone https://github.com/instantlinux/docker-tools.git
cd docker-tools/k8s
make git-dump
~~~

### Variables

These variables can be passed to the image from kubernetes.yaml or docker-compose.yml as needed:

| Variable | Default | Description |
| -------- | ------- | ----------- |
| API_TOKEN_SECRET | | docker secret name of API token as below |
| DEST_DIR | /var/backup/git | destination path |
| HOUR | 0 |cron-syntax backup hour |
| KEEP_DAYS | 31 | days of snapshots to keep |
| MINUTE | 45 | cron-syntax minutes past hour |
| REPO_PREFIX | git@github.com:instantlinux/ | prefix for each repository URI |
| REPOS | | repository URIs to back up |
| SSHKEY_SECRET | git-dump_sshkey | docker secret name as below |
| SSH_PORT | 22 | TCP port of git service |
| TZ | UTC | time zone |

### Secrets

| Secret | Description |
| ------ | ----------- |
| git-dump_sshkey | read-only key for git repos (override name above) |
| xxx-api-token | API token for fetching project list from gitlab |

### Contributing

If you want to make improvements to this image, see [CONTRIBUTING](https://github.com/instantlinux/docker-tools/blob/main/CONTRIBUTING.md).

[![](https://img.shields.io/badge/license-GPL--2.0-red.svg)](https://choosealicense.com/licenses/gpl-2.0/ "License badge") [![](https://img.shields.io/badge/code-git%2Fgit.git-blue.svg)](https://git.kernel.org/pub/scm/git/git.git/ "Code repo")
