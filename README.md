## Practical Docker Tools

This repo is a collection of images and swarm stack definitions for
managing a small software-dev shop using free software. Contents:

| Directory | Description |
| --------- | ----------- |
| containers | special-case containers needing a script |
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

**Networking and support**
* blacklist - a local rbldnsd for spam control
* ez-ipupdate - Dynamic DNS client
* guacamole - authenticated remote-desktop server
* logspout - central logging for Docker
* mysqldump - per-database alternative to xtrabackup
* postfix - compact general-purpose image in 11MB
* postfix-python - postfix with spam-control scripts
* rsyslogd - logger in a 13MB image
* spamassassin - spam control daemon
* splunk - the free version
* swarm-sync - poor-man's SAN for persistent storage

**Entertainment**
* mt-daapd - iTunes server
* mythsuse - MythTV backend
* weewx - Weather station software (Davis VantagePro2 etc.)

Contents created 2017 under [Apache 2.0 License](https://www.apache.org/licenses/LICENSE-2.0) by Rich Braun.
