## ddclient
[![](https://img.shields.io/docker/v/instantlinux/ddclient?sort=date)](https://hub.docker.com/r/instantlinux/ddclient/tags "Version badge") [![](https://img.shields.io/docker/image-size/instantlinux/ddclient?sort=date)](https://github.com/instantlinux/docker-tools/-/blob/main/images/ddclient "Image badge") ![](https://img.shields.io/badge/platform-amd64%20arm64%20arm%2Fv6%20arm%2Fv7-blue "Platform badge") [![](https://img.shields.io/badge/dockerfile-latest-blue)](https://gitlab.com/instantlinux/docker-tools/-/blob/main/images/ddclient/Dockerfile "dockerfile")

Dynamic-DNS client - automatically updates a public DNS name with your dynamic IP address. Set this up under Kubernetes or Docker Swarm to ensure it's always running.

First create a secret:

    echo -n user:pw ddclient-user
    kubectl create secret generic ddclient-user --from-file=./ddclient-user
    # or #
    docker secret create ddclient-user ddclient-user

Then deploy this service, see the example [helm](https://github.com/instantlinux/docker-tools/tree/main/images/ddclient/helm) / docker-compose.yml files. Available environment variables are:

| Variable | Default | Description |
| -------- |-------- | ----------- |
| HOST | | the DNS name whose address you want kept up to date |
| INTERVAL | 3600 | poll interval in seconds |
| IPLOOKUP_URI | http://ipinfo.io/ip | a URI that returns the IPv4 address to be assigned |
| SERVER | members.easydns.com | remote dynamic-DNS server hostname|
| SERVICE_TYPE | easydns | DNS vendor, see [available services](https://github.com/ddclient/ddclient/blob/develop/README.md)
| USER_LOGIN | |Login name|
| USER_SECRET | ddclient-user |Name of the Docker secret containing password |

Instead of supplying these variables, if your provider requires more parameters than shown above, you can volume-mount the configuration as `/etc/ddclient/ddclient.conf`.

Logging is set to `verbose` in order to have any logging at all; it's not possible to reduce verbosity to a lower level than about 18 lines of output per interval without modifying source code.

This repo has complete instructions for
[building a kubernetes cluster](https://github.com/instantlinux/docker-tools/blob/main/k8s/README.md) where you can launch with [helm](https://github.com/instantlinux/docker-tools/tree/main/images/ddclient/helm) or [kubernetes.yaml](https://github.com/instantlinux/docker-tools/blob/main/images/ddclient/kubernetes.yaml) using _make_ and customizing [Makefile.vars](https://github.com/instantlinux/docker-tools/blob/main/k8s/Makefile.vars) after cloning this repo:
~~~
git clone https://github.com/instantlinux/docker-tools.git
cd docker-tools/k8s
make ddclient
~~~

### Contributing

If you want to make improvements to this image, see [CONTRIBUTING](https://github.com/instantlinux/docker-tools/blob/main/CONTRIBUTING.md).

[![](https://img.shields.io/badge/license-GPL--2.0-red.svg)](https://choosealicense.com/licenses/gpl-2.0/ "License badge") [![](https://img.shields.io/badge/code-ddclient%2Fddclient-blue.svg)](https://github.com/ddclient/ddclient "Code repo")
