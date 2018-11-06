## Practical Docker Tools

This repo is a collection of images and swarm stack definitions for
managing a software-dev organization using free software. Contents:

| Directory | Description |
| --------- | ----------- |
| ansible | build your own docker cluster |
| images | images which are published to Docker Hub |
| k8s | container resources in kubernetes yaml format |
| lib/build | build makefile and tools |
| services | docker-compose services that can't run in swarm |
| ssl | PKI certificate tools |
| stacks | container resources in docker-compose format |

Find images at [docker hub/instantlinux](https://hub.docker.com/r/instantlinux/).

Stack definitions include:

**Developer infrastructure**

| Service | Version | Notes |
| --- | --- | --- |
| artifactory | ** | binary repo |
| gitlab | ** | CI server and git repo |
| git-pull | [![](https://images.microbadger.com/badges/version/instantlinux/git-pull.svg)](https://microbadger.com/images/instantlinux/git-pull "Version badge") | sync git repo across swarm |
| jenkins | [![](https://images.microbadger.com/badges/version/instantlinux/jenkins-master.svg)](https://microbadger.com/images/instantlinux/jenkins-master "Version badge") | CI server |
| jira | ** | ticket tracking |
| mariadb-galera | [![](https://images.microbadger.com/badges/version/instantlinux/mariadb-galera.svg)](https://microbadger.com/images/instantlinux/mariadb-galera "Version badge") | automatic cluster setup|
| nexus | ** | binary repo with docker registry |
| wordpress | ** | |

**Networking and support**

| Service | Version | Notes |
| --- | --- | --- |
| authelia | ** | single-signon multi-factor auth |
| cloud | ** | nextcloud, private sync like Apple iCloud |
| docs | [![](https://images.microbadger.com/badges/version/instantlinux/open-xchange-appsuite.svg)](https://microbadger.com/images/instantlinux/open-xchange-appsuite "Version badge") | OX Appsuite, private cloud like Google Docs |
| duplicati | [![](https://images.microbadger.com/badges/version/instantlinux/duplicati.svg)](https://microbadger.com/images/instantlinux/duplicati "Version badge") | backups |
| ez-ipupdate | [![](https://images.microbadger.com/badges/version/instantlinux/ez-ipupdate.svg)](https://microbadger.com/images/instantlinux/ez-ipupdate "Version badge") | Dynamic DNS client |
| haproxy-keepalived | [![](https://images.microbadger.com/badges/version/instantlinux/haproxy-keepalived.svg)](https://microbadger.com/images/instantlinux/haproxy-keepalived "Version badge") | load balancer |
| guacamole | ** | authenticated remote-desktop server |
| logspout | ** | central logging for Docker |
| mysqldump | [![](https://images.microbadger.com/badges/version/instantlinux/mysqldump.svg)](https://microbadger.com/images/instantlinux/mysqldump "Version badge") | per-database alternative to xtrabackup |
| nagiosql | [![](https://images.microbadger.com/badges/version/instantlinux/nagiosql.svg)](https://microbadger.com/images/instantlinux/nagiosql "Version badge") | NagiosQL with Nagios Core v4 for monitoring |
| nut-upsd | [![](https://images.microbadger.com/badges/version/instantlinux/nut-upsd.svg)](https://microbadger.com/images/instantlinux/nut-upsd "Version badge") | Network UPS Tools |
| rsyslogd | ** | logger in a 13MB image |
| samba | [![](https://images.microbadger.com/badges/version/instantlinux/samba.svg)](https://microbadger.com/images/instantlinux/samba "Version badge") | file server |
| samba-dc | [![](https://images.microbadger.com/badges/version/instantlinux/samba-dc.svg)](https://microbadger.com/images/instantlinux/samba-dc "Version badge") | Active-Directory compatible domain controller |
| [secondshot](https://github.com/instantlinux/secondshot) | [![](https://images.microbadger.com/badges/version/instantlinux/secondshot.svg)](https://microbadger.com/images/instantlinux/secondshot "Version badge") | rsnapshot-based backups |
| splunk | ** | the free version |
| swarm-sync | [![](https://images.microbadger.com/badges/version/instantlinux/swarm-sync.svg)](https://microbadger.com/images/instantlinux/swarm-sync "Version badge") | poor-man's SAN for persistent storage |
| udp-nginx-proxy | [![](https://images.microbadger.com/badges/version/instantlinux/udp-nginx-proxy.svg)](https://microbadger.com/images/instantlinux/udp-nginx-proxy "Version badge") | UDP load-balancer |
| vsftpd | [![](https://images.microbadger.com/badges/version/instantlinux/vsftpd.svg)](https://microbadger.com/images/instantlinux/vsftpd "Version badge") | ftp server |

**Email**

| Service | Version | Notes |
| --- | --- | --- |
| blacklist | [![](https://images.microbadger.com/badges/version/instantlinux/blacklist.svg)](https://microbadger.com/images/instantlinux/blacklist "Version badge") | a local rbldnsd for spam control |
| dovecot | [![](https://images.microbadger.com/badges/version/instantlinux/dovecot.svg)](https://microbadger.com/images/instantlinux/dovecot "Version badge") | imapd server |
| postfix | [![](https://images.microbadger.com/badges/version/instantlinux/postfix.svg)](https://microbadger.com/images/instantlinux/postfix "Version badge") | compact general-purpose image in 11MB |
| postfix-python | [![](https://images.microbadger.com/badges/version/instantlinux/postfix-python.svg)](https://microbadger.com/images/instantlinux/postfix-python "Version badge") | postfix with spam-control scripts |
| rainloop | ** | webmail imapd-client server |
| squirrelmail | [![](https://images.microbadger.com/badges/version/instantlinux/squirrelmail.svg)](https://microbadger.com/images/instantlinux/squirrelmail "Version badge") | older version of Squirrelmail |
| spamassassin | [![](https://images.microbadger.com/badges/version/instantlinux/spamassassin.svg)](https://microbadger.com/images/instantlinux/spamassassin "Version badge") | spam control daemon |

**Entertainment**

| Service | Version | Notes |
| --- | --- | --- |
| davite | [![](https://images.microbadger.com/badges/version/instantlinux/davite.svg)](https://microbadger.com/images/instantlinux/davite "Version badge") | party-invites manager like eVite |
| mt-daapd | [![](https://images.microbadger.com/badges/version/instantlinux/mt-daapd.svg)](https://microbadger.com/images/instantlinux/mt-daapd "Version badge") | iTunes server |
| mythtv-backend | [![](https://images.microbadger.com/badges/version/instantlinux/mythtv-backend.svg)](https://microbadger.com/images/instantlinux/mythtv-backend "Version badge") | MythTV backend |
| weewx | [![](https://images.microbadger.com/badges/version/instantlinux/weewx.svg)](https://microbadger.com/images/instantlinux/weewx "Version badge") | Weather station software (Davis VantagePro2 etc.) |

Contents created 2017-18 under [Apache 2.0 License](https://www.apache.org/licenses/LICENSE-2.0) by Rich Braun.
