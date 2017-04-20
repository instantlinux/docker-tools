## Non-swarm containers

The container definitions here represent the few cases where limitations
of Docker's swarm implementation made it difficult or impossible to
run them via 'docker stack deploy'. Example:

* The MythTV backend needs a special direct-attached network bridge
for the Silicondust HD HomeRun network tuner to reach it.

* mt-daapd (iTunes server) needs to run on host network for mDNS (avahi) service
discovery.

Each container defined here is invoked via start.sh from one of the docker hosts.
Failover requires manual intervention.

