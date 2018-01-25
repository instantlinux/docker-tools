## duplicati

[![](https://images.microbadger.com/badges/version/instantlinux/duplicati.svg)](https://microbadger.com/images/instantlinux/duplicati "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/duplicati.svg)](https://microbadger.com/images/instantlinux/duplicati "Image badge") [![](https://images.microbadger.com/badges/commit/instantlinux/duplicati.svg)](https://microbadger.com/images/instantlinux/duplicati "Commit badge")

Duplicati 2.0 software for secure online/local backups. After CrashPlan discontinued its individual-user subscription service in 2018, this along with the BackBlaze B2 or Amazon S3 service is the most-active open-source project and is the best alternative for Linux users. Project organizers tag releases "beta", "experimental", and "canary"; to take advantage of the rapid pace of development, this container image provides the experimental release which has the most-current stable feature set. Use the linuxserver/duplicati:latest image if you wish to run the older beta version.

### Usage

In your docker-compose file, add the list of volumes you wish to back up under /backup. If you're backing up a server, set the PUID environment value to root user (0). Bring up the stack and define backup configurations; see [software documentation](https://github.com/duplicati/duplicati/wiki). All other configuration is done via the UI on TCP port 8200.

An example compose file is provided here in docker-compose.yml.

### Variables

Variable | Default | Description |
-------- | ------- | ----------- |
PGID | 34 | Group ID for backup user
PUID | 34 | User ID

[![](https://images.microbadger.com/badges/license/instantlinux/duplicati.svg)](https://microbadger.com/images/instantlinux/duplicati "License badge")
