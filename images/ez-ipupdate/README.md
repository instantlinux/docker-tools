## ez-ipupdate
[![](https://img.shields.io/docker/v/instantlinux/ez-ipupdate?sort=date)](https://hub.docker.com/r/instantlinux/ez-ipupdate/tags "Version badge") [![](https://img.shields.io/docker/image-size/instantlinux/ez-ipupdate?sort=date)](https://github.com/instantlinux/docker-tools/-/blob/main/images/ez-ipupdate "Image badge") ![](https://img.shields.io/badge/platform-amd64%20arm64%20arm%2Fv6%20arm%2Fv7-blue "Platform badge") [![](https://img.shields.io/badge/dockerfile-latest-blue)](https://gitlab.com/instantlinux/docker-tools/-/blob/main/images/ez-ipupdate/Dockerfile "dockerfile")

Dynamic-DNS client - automatically updates a public DNS name with your dynamic IP address. Set this up under Kubernetes or Docker Swarm to ensure it's always running.

*Status:* This is sunsetted, use the [instantlinux/ddclient](https://hub.docker.com/repository/docker/instantlinux/ddclient) image if you can.

First create a secret:

    echo -n user:pw ez-ipupdate-user
    kubectl create secret generic ez-ipupdate-user --from-file=./ez-ipupdate-user
    # or #
    docker secret create ez-ipupdate-user ez-ipupdate-user

Then deploy this service, see the example [helm](https://github.com/instantlinux/docker-tools/tree/main/images/ez-ipupdate/helm) / docker-compose.yml files. Available environment variables are:

| Variable | Default | Description |
| -------- |-------- | ----------- |
| HOST | | the DNS name whose address you want kept up to date |
| INTERVAL | 3600 | poll interval in seconds |
| IPLOOKUP_URI | http://ipinfo.io/ip | a URI that returns the IPv4 address to be assigned |
| SERVICE_TYPE | easydns | DNS vendor, see [available services](http://leaf.sourceforge.net/doc/bucu-ezipupd.html) |
| USER_SECRET | ez-ipupdate-user |Name of the Docker secret to deploy |

This repo has complete instructions for
[building a kubernetes cluster](https://github.com/instantlinux/docker-tools/blob/main/k8s/README.md) where you can deploy with [helm](https://github.com/instantlinux/docker-tools/tree/main/images/ez-ipupdate/helm) or [kubernetes.yaml](https://github.com/instantlinux/docker-tools/blob/main/images/ez-ipupdate/kubernetes.yaml) using _make_ and customizing [Makefile.vars](https://github.com/instantlinux/docker-tools/blob/main/k8s/Makefile.vars) after cloning this repo:
~~~
git clone https://github.com/instantlinux/docker-tools.git
cd docker-tools/k8s
make ez-ipupdate
~~~

### Contributing

If you want to make improvements to this image, see [CONTRIBUTING](https://github.com/instantlinux/docker-tools/blob/main/CONTRIBUTING.md).

[![](https://img.shields.io/badge/license-GPL--2.0-red.svg)](https://choosealicense.com/licenses/gpl-2.0/ "License badge") [![](https://img.shields.io/badge/code-sourceforge%2Fez_ipupdate-blue.svg)](https://sourceforge.net/projects/ez-ipupdate/ "Code repo")
