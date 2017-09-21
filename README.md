## Practical Docker Tools

This repo is a collection of images and swarm stack definitions for
managing a small software-dev shop using free software. Contents:

| Directory | Description |
| --------- | ----------- |
| images | images which are published to Docker Hub |
| lib/build | build makefile and tools |
| services | docker-compose services that can't run in swarm |
| ssl | PKI certificate tools |
| stacks | swarm stacks in docker-compose format |

Stack definitions include:

**Developer infrastructure**
* artifactory
* gitlab
* git-pull
* jenkins
* jira
* mariadb (clustered)
* wordpress

**Networking and support**
* authelia - single-signon multi-factor auth
* cloud - nextcloud, private sync like Apple iCloud
* crashplan - backups
* docs - OX Appsuite, private cloud like Google Docs
* ez-ipupdate - Dynamic DNS client
* guacamole - authenticated remote-desktop server
* logspout - central logging for Docker
* mysqldump - per-database alternative to xtrabackup
* nut-upsd - Network UPS Tools
* rsyslogd - logger in a 13MB image
* splunk - the free version
* swarm-sync - poor-man's SAN for persistent storage

** Email**
* blacklist - a local rbldnsd for spam control
* dovecot - imapd server
* postfix - compact general-purpose image in 11MB
* postfix-python - postfix with spam-control scripts
* squirrelmail - older version of Squirrelmail
* spamassassin - spam control daemon

**Entertainment**
* davite - party-invites manager like eVite
* mt-daapd - iTunes server
* mythsuse - MythTV backend
* weewx - Weather station software (Davis VantagePro2 etc.)

Contents created 2017 under [Apache 2.0 License](https://www.apache.org/licenses/LICENSE-2.0) by Rich Braun.
