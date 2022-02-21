## python-builder
[![](https://img.shields.io/docker/v/instantlinux/python-builder?sort=date)](https://hub.docker.com/r/instantlinux/python-builder/tags "Version badge") [![](https://img.shields.io/docker/image-size/instantlinux/python-builder?sort=date)](https://github.com/instantlinux/docker-tools/-/blob/main/images/python-builder "Image badge") ![](https://img.shields.io/badge/platform-amd64%20arm64%20arm%2Fv7-blue "Platform badge") [![](https://img.shields.io/badge/dockerfile-latest-blue)](https://gitlab.com/instantlinux/docker-tools/-/blob/main/images/python-builder/Dockerfile "dockerfile")

A multi-arch image with basic build tools (python/gcc) for GitLab-CI executors.

### Usage
Define this in a .gitlab.yml job:
```
job:
  image: instantlinux/python-builder:latest
  script: make analysis
```

Look in the [Pipfile](https://github.com/instantlinux/docker-tools/blob/main/images/python-builder/Pipfile) of this image to see what tools are provided.

### Variables

Variable | Default | Description
-------- | ------- | -----------
TZ | UTC | time zone

### Contributing

If you want to make improvements to this image, see [CONTRIBUTING](https://github.com/instantlinux/docker-tools/blob/main/CONTRIBUTING.md).

[![](https://img.shields.io/badge/license-Apache--2.0-red.svg)](https://choosealicense.com/licenses/apache-2.0/ "License badge")
