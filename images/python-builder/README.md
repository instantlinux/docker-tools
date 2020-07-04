## python-builder
[![](https://img.shields.io/docker/v/instantlinux/python-builder?sort=date)](https://microbadger.com/images/instantlinux/python-builder "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/python-builder.svg)](https://microbadger.com/images/instantlinux/python-builder "Image badge") ![](https://img.shields.io/badge/platform-amd64%20arm64%20arm%2Fv6%20arm%2Fv7-blue "Platform badge") [![](https://img.shields.io/badge/dockerfile-latest-blue)](https://gitlab.com/instantlinux/docker-tools/-/blob/master/images/python-builder/Dockerfile "dockerfile")

A multi-arch image with basic build tools (python/gcc) for GitLab-CI executors.

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

[![](https://img.shields.io/badge/license-Apache--2.0-red.svg)](https://choosealicense.com/licenses/apache-2.0/ "License badge")
