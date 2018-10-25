## python-builder
[![](https://images.microbadger.com/badges/version/instantlinux/python-builder.svg)](https://microbadger.com/images/instantlinux/python-builder "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/python-builder.svg)](https://microbadger.com/images/instantlinux/python-builder "Image badge") [![](https://images.microbadger.com/badges/commit/instantlinux/python-builder.svg)](https://microbadger.com/images/instantlinux/python-builder "Commit badge")

An image with basic build tools (python/gcc) for GitLab-CI
executors.

### Usage
Define this in a .gitlab.yml job:
```
job:
  image: instantlinux/python-builder:latest
  script: echo hello world
```

### Variables

Variable | Default | Description
-------- | ------- | -----------
TZ | UTC | time zone

[![](https://images.microbadger.com/badges/license/instantlinux/python-builder.svg)](https://microbadger.com/images/instantlinux/python-builder "License badge")
