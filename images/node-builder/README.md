## node-builder
[![](https://images.microbadger.com/badges/version/instantlinux/node-builder.svg)](https://microbadger.com/images/instantlinux/node-builder "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/node-builder.svg)](https://microbadger.com/images/instantlinux/node-builder "Image badge") [![](https://images.microbadger.com/badges/commit/instantlinux/node-builder.svg)](https://microbadger.com/images/instantlinux/node-builder "Commit badge")

A node image with basic build tools (node/npm/yarn/docker/make) and the react-admin framework for GitLab-CI executors.

### Usage
Define this in a .gitlab.yml job:
```
job:
  image: instantlinux/node-builder:latest
  script: echo hello world
```

### Variables

Variable | Default | Description
-------- | ------- | -----------
TZ | UTC | time zone

[![](https://images.microbadger.com/badges/license/instantlinux/node-builder.svg)](https://microbadger.com/images/instantlinux/node-builder "License badge")
