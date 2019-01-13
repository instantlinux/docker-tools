## git-pull
[![](https://images.microbadger.com/badges/version/instantlinux/git-pull.svg)](https://microbadger.com/images/instantlinux/git-pull "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/git-pull.svg)](https://microbadger.com/images/instantlinux/git-pull "Image badge") [![](https://images.microbadger.com/badges/commit/instantlinux/git-pull.svg)](https://microbadger.com/images/instantlinux/git-pull "Commit badge")

Git pull, plain and simple (why wasn't there already a published
container to do this)?

### Usage

This provides a way to distribute administrative configuration files
or other content across each instance of a cluster.

See the kubernetes.yaml / docker-compose.yml file for a simple example
(add additional services to pick up content pulled by this image). A
Makefile is provided to generate the deploy key as a Docker secret;
after doing so, upload the new public key to your git server.

This image will continuously update a path on each Docker cluster node
from contents of a particular repo; if you define an environment
variable ADMIN_PATH (or Docker named volume) and place configuration
files for each service in subdirectories of that repo, this is a handy
way of propagating configurations (such as /etc files) across the
cluster. Note that any Docker mounts must be made with ro
(read-only) set to keep this container running without merge conflicts.

This repo has complete instructions for
[building a kubernetes cluster](https://github.com/instantlinux/docker-tools/blob/master/k8s/README.md) where you can deploy [kubernetes.yaml](kubernetes.yaml) with the Makefile or:
~~~
cat kubernetes.yaml | envsubst | kubectl apply -f -
~~~

There's less need for this tool under Kubernetes than Docker Swarm: see
the [ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/) documentation for the current recommended method for making config files available.

### Variables

| Variable | Description |
| -------- | ----------- |
|DEST| destination directory under /git |
|GIT_COMMIT| branch name or hash |
|GIT_HOST| hostname of git repo (for keyscan) |
|GIT_REPO| repository name |
|INTERVAL| polling interval, 0 for one-shot|

### Secrets
| Secret | Description |
| ------ | ----------- |
|git-deploy-sshkey| private half of deploy keypair|

[![](https://images.microbadger.com/badges/license/instantlinux/git-pull.svg)](https://microbadger.com/images/instantlinux/git-pull "License badge")
