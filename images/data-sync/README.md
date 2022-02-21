## data-sync
[![](https://img.shields.io/docker/v/instantlinux/data-sync?sort=date)](https://hub.docker.com/r/instantlinux/data-sync/tags "Version badge") [![](https://img.shields.io/docker/image-size/instantlinux/data-sync?sort=date)](https://github.com/instantlinux/docker-tools/-/blob/main/images/data-sync "Image badge") ![](https://img.shields.io/badge/platform-amd64%20arm64-blue "Platform badge") [![](https://img.shields.io/badge/dockerfile-latest-blue)](https://gitlab.com/instantlinux/docker-tools/-/blob/main/images/data-sync/Dockerfile "dockerfile")

This provides HA storage for a bare-metal cluster. NAS servers are not usually HA and SAN installations are costly. Add this resource definition to your Kubernetes cluster and the volumes you mount under a directory /var/data-sync will be kept in sync using the [unison](https://www.cis.upenn.edu/~bcpierce/unison/) file synchronizer from UPenn.

At present this is far easier to set up than other clustering technologies and results in a stable system with an easily-tracked audit log. I've tried and abandoned CephFS, GlusterFS, DRBD, and others; unison has been running well for several trouble-free years. It works like, and is as easy to understand as, a bidirectional rsync.

### Usage

To generate two ssh keypairs (stored in a single secret) and label your nodes,
invoke the following:
~~~bash
HOST1=<host1> HOST2=<host2> make label_nodes
make data-sync
~~~
(This needs two keypairs so it can securely invoke both rsync and unison.)

Define any custom directives in the data-sync ConfigMap, and set environment variable $SERVICE_NAME to data-sync (you can run more than one copy of this by setting different SERVICE_NAME and ConfigMap names).

This repo has complete instructions for
[building a kubernetes cluster](https://github.com/instantlinux/docker-tools/blob/main/k8s/README.md) where you can deploy with [helm](https://github.com/instantlinux/docker-tools/tree/main/images/data-sync/helm) or [kubernetes.yaml](https://github.com/instantlinux/docker-tools/blob/main/images/data-sync/kubernetes.yaml) using _make_ and customizing [Makefile.vars](https://github.com/instantlinux/docker-tools/blob/main/k8s/Makefile.vars) after cloning this repo:
~~~
git clone https://github.com/instantlinux/docker-tools.git
cd docker-tools/k8s
make data-sync
~~~

For monitoring, put nagios-nrpe-data-sync.cfg into your /etc/nagios
directory and add an NRPE check_data_sync check to the primary host's
list of services. Set the warning/critical values as appropriate for
your polling frequency in the cfg file.

If you add any mount points underneath the synchronized volume, restart this service.

Files in the ConfigMap (mounted as /etc/unison.d) contain customizable directives as defined in [unison-manual](https://www.cis.upenn.edu/~bcpierce/unison/download/releases/stable/unison-manual.html). An example common.prf from this repo is installed if you don't define this.

To scale this beyond the first two nodes, add the service.data-sync=allow label to more nodes and invoke the _kubectl scale_ command. The main scaling issue you'll run into with _unison_ is high memory usage as the number of nodes and files increases. The host with ordinal 0 is configured as the hub of a star topology as defined in the UPenn doc.

Not running under Kubernetes? Omit PEERNAME value on the primary node, and set PEERNAME to the primary's hostname on each of the additional nodes.

### Variables

These variables can be passed to the image from helm's values.yaml, kubernetes.yaml or docker-compose.yml as needed:

| Variable | Default | Description |
| -------- | ------- | ----------- |
| PEERNAME | | destination peer's hostname (if not running in k8s) |
| SECRET | data-sync_sshkey | override name of secret described below |
| PUBKEY1 |  | public key as stored in configmap |
| PUBKEY2 |  | public key as stored in configmap |
| RRSYNCROOT | / | root path allowed by rrsync |
| SYNC_INTERVAL | 5 | frequency, in minutes |

Interval is slightly inexact, intentionally. An earlier version of this used cron for precision, but that causes more resource contention than necessary.

### Secrets
| Secret | Description |
| ------ | ----------- |
| data-sync-sshkey1 | private half of ssh keypair |
| data-sync-sshkey2 | private half of ssh keypair |

### Contributing

If you want to make improvements to this image, see [CONTRIBUTING](https://github.com/instantlinux/docker-tools/blob/main/CONTRIBUTING.md).

[![](https://img.shields.io/badge/license-Apache--2.0-red.svg)](https://choosealicense.com/licenses/apache-2.0/ "License badge") [![](https://img.shields.io/badge/code-bcpierce00%2Funison-blue.svg)](https://github.com/bcpierce00/unison "Code repo")
