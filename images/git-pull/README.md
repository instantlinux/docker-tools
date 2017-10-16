## git-pull
[![](https://images.microbadger.com/badges/version/instantlinux/git-pull.svg)](https://microbadger.com/images/instantlinux/git-pull "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/git-pull.svg)](https://microbadger.com/images/instantlinux/git-pull "Image badge") [![](https://images.microbadger.com/badges/commit/instantlinux/git-pull.svg)](https://microbadger.com/images/instantlinux/git-pull "Commit badge")

Git pull, plain and simple (why wasn't there already a published
container to do this)?

### Usage

See the docker-compose.yml file for a simple example (add additional
services to pick up content pulled by this image). A Makefile is
provided to generate the deploy key as a Docker secret; after doing so,
upload the new public key to your git server.

This image will continously update a path on each Docker swarm node
from contents of a particular repo; if you define an environment
variable ADMIN_PATH (or Docker named volume) and place configuration
files for each service in subdirectories of that repo, this is a handy
way of propagating configurations (such as /etc files) across the
cluster. Note that any Docker mounts must be made with ro
(read-only) set to keep this container running without merge conflicts.

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
|git-deploy_sshkey| private half of deploy keypair|

[![](https://images.microbadger.com/badges/license/instantlinux/git-pull.svg)](https://microbadger.com/images/instantlinux/git-pull "License badge")
