## swarm-sync
[![](https://images.microbadger.com/badges/version/instantlinux/swarm-sync.svg)](https://microbadger.com/images/instantlinux/swarm-sync "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/swarm-sync.svg)](https://microbadger.com/images/instantlinux/swarm-sync "Image badge") [![](https://images.microbadger.com/badges/commit/instantlinux/swarm-sync.svg)](https://microbadger.com/images/instantlinux/swarm-sync "Commit badge")

This HA tool provides sync for persistent storage between two swarm nodes,
with automatic recovery after a failure of either node.

If you don't have a SAN or cloud-infrastructure to support persistent
volumes, build a stack using this container. Then your other stacks can
reference volume mount points as subdirectories of /var/lib/docker/share.

At present this is far easier to set up than other clustering technologies.

### Usage

To generate an ssh keypair for synchronization and label your nodes,
invoke the following:
~~~bash
PRIMARY=<host1> PEER=<host2> make label_nodes
make
~~~
Then deploy the stack:
~~~
docker stack deploy -c ../../swarm-sync.yml swarm-sync
~~~
Then use this compose-file constraint in your stack definitions:

~~~yml
    deploy:
      replicas: 1
      placement:
        constraints:
        - node.labels.swarm-sync-member == true
~~~
For monitoring, put nagios-nrpe-swarm-sync.cfg into your /etc/nagios
directory and add an NRPE check_swarm_sync check to the primary host's
list of services. Set the warning/critical values as appropriate for
your polling frequency in the cfg file.

### Variables

| Variable | Default | Description |
| -------- | ------- | ----------- |
| SECRET | swarm-sync_sshkey | name of secret with private key |
| SYNC_INTERVAL | 5 | frequency, in minutes |
| SYNC_ROLE | primary | role, primary or secondary |
| SYNC_SSHKEY |  | public key |

[![](https://images.microbadger.com/badges/license/instantlinux/swarm-sync.svg)](https://microbadger.com/images/instantlinux/swarm-sync "License badge")
