## git-dump
[![](https://images.microbadger.com/badges/version/instantlinux/git-dump.svg)](https://microbadger.com/images/instantlinux/git-dump "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/git-dump.svg)](https://microbadger.com/images/instantlinux/git-dump "Image badge") [![](https://images.microbadger.com/badges/commit/instantlinux/git-dump.svg)](https://microbadger.com/images/instantlinux/git-dump "Commit badge")

This dockerizes a simple script I wrote years ago to create git bundle
backups of a private git server.

The example kubernetes / docker-compose service definition will cause
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
[building a kubernetes cluster](https://github.com/instantlinux/docker-tools/blob/master/k8s/README.md) where you can deploy [kubernetes.yaml](https://github.com/instantlinux/docker-tools/blob/master/images/git-dump/kubernetes.yaml) with the Makefile or:
~~~
cat kubernetes.yaml | envsubst | kubectl apply -f -
~~~

### Variables

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
[![](https://images.microbadger.com/badges/license/instantlinux/git-dump.svg)](https://microbadger.com/images/instantlinux/git-dump "License badge")
