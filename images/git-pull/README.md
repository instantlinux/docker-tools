## git-pull
[![](https://img.shields.io/docker/v/instantlinux/git-pull?sort=date)](https://hub.docker.com/r/instantlinux/git-pull/tags "Version badge") [![](https://img.shields.io/docker/image-size/instantlinux/git-pull?sort=date)](https://github.com/instantlinux/docker-tools/-/blob/main/images/git-pull "Image badge") ![](https://img.shields.io/badge/platform-amd64%20arm64%20arm%2Fv6%20arm%2Fv7-blue "Platform badge") [![](https://img.shields.io/badge/dockerfile-latest-blue)](https://gitlab.com/instantlinux/docker-tools/-/blob/main/images/git-pull/Dockerfile "dockerfile")

Git pull, plain and simple (why wasn't there already a published
container to do this?) - with multi-architecture support.

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
[building a kubernetes cluster](https://github.com/instantlinux/docker-tools/blob/main/k8s/README.md) where you can launch with [helm](https://github.com/instantlinux/docker-tools/tree/main/images/git-pull/helm) or [kubernetes.yaml](https://github.com/instantlinux/docker-tools/blob/main/images/git-pull/kubernetes.yaml) using _make_ and customizing [Makefile.vars](https://github.com/instantlinux/docker-tools/blob/main/k8s/Makefile.vars) after cloning this repo:
~~~
git clone https://github.com/instantlinux/docker-tools.git
cd docker-tools/k8s
# admin-git.yaml is a symlink to git-pull/kubernetes.yaml
make admin-git
~~~

There's less need for this tool under Kubernetes than Docker Swarm: see
the [ConfigMap](https://kubernetes.io/docs/tasks/configure-pod-container/configure-pod-configmap/) documentation for the current recommended method for making config files available.

### Variables

| Variable | Default | Description |
| -------- | ------- | ----------- |
|DEST| . | destination directory under /git |
|GIT_COMMIT| master | branch name or hash |
|GIT_HOST| github.com | hostname of git repo (for keyscan) |
|GIT_REPO| uri | repository name |
|INTERVAL| 0 | polling interval, 0 for one-shot|

### Secrets
| Secret | Description |
| ------ | ----------- |
|git-deploy-sshkey| private half of deploy keypair|

### Contributing

If you want to make improvements to this image, see [CONTRIBUTING](https://github.com/instantlinux/docker-tools/blob/main/CONTRIBUTING.md).

[![](https://img.shields.io/badge/license-GPL--2.0-red.svg)](https://choosealicense.com/licenses/gpl-2.0/ "License badge") [![](https://img.shields.io/badge/code-git%2Fgit.git-blue.svg)](https://git.kernel.org/pub/scm/git/git.git/ "Code repo")
