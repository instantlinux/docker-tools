## ez-ipupdate
[![](https://images.microbadger.com/badges/version/instantlinux/ez-ipupdate.svg)](https://microbadger.com/images/instantlinux/ez-ipupdate "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/ez-ipupdate.svg)](https://microbadger.com/images/instantlinux/ez-ipupdate "Image badge") [![](https://images.microbadger.com/badges/commit/instantlinux/ez-ipupdate.svg)](https://microbadger.com/images/instantlinux/ez-ipupdate "Commit badge")

Dynamic-DNS client - automatically updates a public DNS name with your dynamic IP address. Set this up under Kubernetes or Docker Swarm to ensure it's always running.

First create a secret:

    echo -n user:pw ez-ipupdate-user
    kubectl create secret generic ez-ipupdate-user --from-file=./ez-ipupdate-user
    # or #
    docker secret create ez-ipupdate-user ez-ipupdate-user

Then deploy this service, see the example kubernetes.yaml / docker-compose.yml files. Available environment variables are:

| Variable | Default | Description |
| -------- |-------- | ----------- |
| HOST | | the DNS name whose address you want kept up to date |
| INTERVAL | 3600 | poll interval in seconds |
| IPLOOKUP_URI | http://ipinfo.io/ip | a URI that returns the IPv4 address to be assigned |
| SERVICE_TYPE | easydns | DNS vendor, see [available services](http://leaf.sourceforge.net/doc/bucu-ezipupd.html) |
| USER_SECRET | ez-ipupdate-user |Name of the Docker secret to deploy |

This repo has complete instructions for
[building a kubernetes cluster](https://github.com/instantlinux/docker-tools/blob/master/k8s/README.md) where you can deploy [kubernetes.yaml](https://github.com/instantlinux/docker-tools/blob/master/images/ez-ipupdate/kubernetes.yaml) with the Makefile or:
~~~
cat kubernetes.yaml | envsubst | kubectl apply -f -
~~~

[![](https://images.microbadger.com/badges/license/instantlinux/ez-ipupdate.svg)](https://microbadger.com/images/instantlinux/ez-ipupdate "License badge") [![](https://img.shields.io/badge/code-sourceforge%2Fez_ipupdate-blue.svg)](https://sourceforge.net/projects/ez-ipupdate/ "Code repo")
