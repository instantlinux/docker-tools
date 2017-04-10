## swarm-sync

This provides sync for persistent storage between two swarm nodes,
with automatic recovery after a failure of either node.

If you don't have a SAN or cloud-infrastructure to support persistent
volumes, build a stack using this container. Then you can build
additional stacks with their volumes mounted from subdirectories
of /var/lib/docker/share.

## Usage

To generate an ssh keypair for synchronization and label your nodes,
invoke the following:

    PRIMARY=<host1> PEER=<host2> make label_nodes
    make

Then deploy the stack:

    docker stack deploy -c ../../swarm-sync.yml swarm-sync

Then use this compose-file constraint in your stack definitions:

    deploy:
      replicas: 1
      placement:
        constraints:
        - node.labels.swarm-sync-member == true
