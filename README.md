## Practical Docker Tools

This repo is a collection of images and swarm stack definitions for
managing a software-dev organization using free software. Contents:

| Directory | Description |
| --------- | ----------- |
| images | images which are published to Docker Hub |
| lib/build | build makefile and tools |
| services | docker-compose services that can't run in swarm |
| ssl | PKI certificate tools |
| stacks | swarm stacks in docker-compose format |

Find images at [docker hub/instantlinux](https://hub.docker.com/r/instantlinux/).

Stack definitions include:

**Developer infrastructure**
* artifactory
* gitlab
* git-pull
* jenkins
* jira
* mariadb (clustered)
* nexus
* wordpress

**Networking and support**
* authelia - single-signon multi-factor auth
* cloud - nextcloud, private sync like Apple iCloud
* docs - OX Appsuite, private cloud like Google Docs
* duplicati - backups
* ez-ipupdate - Dynamic DNS client
* guacamole - authenticated remote-desktop server
* logspout - central logging for Docker
* mysqldump - per-database alternative to xtrabackup
* nut-upsd - Network UPS Tools
* rsyslogd - logger in a 13MB image
* samba - file server
* samba-dc - Active-Directory compatible domain controller
* splunk - the free version
* swarm-sync - poor-man's SAN for persistent storage
* vsftpd - ftp server

**Email**
* blacklist - a local rbldnsd for spam control
* dovecot - imapd server
* postfix - compact general-purpose image in 11MB
* postfix-python - postfix with spam-control scripts
* squirrelmail - older version of Squirrelmail
* spamassassin - spam control daemon

**Entertainment**
* davite - party-invites manager like eVite
* mt-daapd - iTunes server
* mythtv-backend - MythTV backend
* weewx - Weather station software (Davis VantagePro2 etc.)

Contents created 2017 under [Apache 2.0 License](https://www.apache.org/licenses/LICENSE-2.0) by Rich Braun.
