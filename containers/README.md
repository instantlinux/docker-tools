## Non-swarm containers

The container definitions here represent the few cases where limitations
of Docker's swarm implementation made it difficult or impossible to
run them via 'docker stack deploy'. Examples:

* Etcd instances require IP address settings on command line and thus
far Docker doesn't provide a way to assign static IPs (or separate DNS
host names) via compose in swarm mode.

* The MythTV backend needs a special direct-attached network bridge
for the Silicondust HD HomeRun network tuner to reach it.

* mt-daapd (iTunes server) needs to run on host network for mDNS (avahi) service
discovery.

Each container defined here is invoked via start.sh from one of the docker hosts.
Failover requires manual intervention.

