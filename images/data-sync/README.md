## data-sync
[![](https://images.microbadger.com/badges/version/instantlinux/data-sync.svg)](https://microbadger.com/images/instantlinux/data-sync "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/data-sync.svg)](https://microbadger.com/images/instantlinux/data-sync "Image badge") [![](https://images.microbadger.com/badges/commit/instantlinux/data-sync.svg)](https://microbadger.com/images/instantlinux/data-sync "Commit badge")

This provides HA storage for a bare-metal cluster. NAS servers are not usually HA and SAN installations are costly. Add this resource definition to your Kubernetes cluster and the volumes you mount under a defined $SHARE_PATH will be kept in sync using the [unison](https://www.cis.upenn.edu/~bcpierce/unison/) file synchronizer from UPenn.

At present this is far easier to set up than other clustering technologies and results in a stable system with an easily-tracked audit log. I've tried and abandoned CephFS, GlusterFS, DRBD, and others; unison has been running well for several trouble-free years. It works like, and is as easy to understand as, a bidirectional rsync.

### Usage

To generate an ssh keypair (stored as a configmap and secret) and label your nodes,
invoke the following:
~~~bash
HOST1=<host1> HOST2=<host2> make label_nodes
make data-sync
~~~
Set the value of $PATH_ADM to the top-level directory synchronized by the admin-git (git-pull) service also defined in this repo, and $SERVICE_NAME to data-sync (you can run more than one copy of this by setting different SERVICE_NAME and PATH_ADM values).

Then deploy the resources:
~~~
cat kubernetes.yaml | envsubst | kubectl apply -f -
~~~

For monitoring, put nagios-nrpe-data-sync.cfg into your /etc/nagios
directory and add an NRPE check_data_sync check to the primary host's
list of services. Set the warning/critical values as appropriate for
your polling frequency in the cfg file.

If you add any mount points underneath the synchronized volume, restart this service.

Files in $PATH_ADM/$SERVICE_NAME mounted as /etc/unison.d contain customizable directives as defined in [unison-manual](https://www.cis.upenn.edu/~bcpierce/unison/download/releases/stable/unison-manual.html). An example common.prf from this repo is installed if you don't add this path.

To scale this beyond the first two nodes, add the service.data-sync=allow label to more nodes and invoke the _kubectl scale_ command. The main scaling issue you'll run into with _unison_ is high memory usage as the number of nodes and files increases. The host with ordinal 0 is configured as the hub of a star topology as defined in the UPenn doc.

### Variables

| Variable | Default | Description |
| -------- | ------- | ----------- |
| SECRET | data-sync_sshkey | override name of secret described below |
| SYNC_SSHKEY |  | public key as stored in configmap |
| SYNC_INTERVAL | 5 | frequency, in minutes |

### Secrets
Secret | Description
------ | -----------
data-sync-sshkey | private half of ssh keypair

### Status

The swarm-sync image has been stable since early 2017; as of Nov 2018 this is new for k8s so there might be memory-related issues to resolve.

[![](https://images.microbadger.com/badges/license/instantlinux/data-sync.svg)](https://microbadger.com/images/instantlinux/data-sync "License badge")
