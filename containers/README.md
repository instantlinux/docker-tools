## Non-swarm containers

The container definitions here represent the cases where limitations
of Docker's swarm implementation made it difficult or impossible to
run them via 'docker stack deploy'. Example:

* The MythTV backend needs a special direct-attached network bridge
for the Silicondust HD HomeRun network tuner to reach it.

Each container defined here is invoked via start.sh from one of the docker hosts.
Failover requires manual intervention.

