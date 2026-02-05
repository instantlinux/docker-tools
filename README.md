## Practical Docker Tools

[![](https://gitlab.com/instantlinux/docker-tools/badges/master/pipeline.svg)](https://gitlab.com/instantlinux/docker-tools/pipelines "pipelines")

Kubernetes is hard--or is it? This repo is a collection of
multi-platform images and container resource definitions for managing
a software-dev organization using Kubernetes. These tools make it
easy. Contents:

| Directory | Description |
| --------- | ----------- |
| ansible | build your own Kubernetes cluster |
| images | images which are published to Docker Hub |
| k8s | container resources in kubernetes yaml format |
| lib/build | build makefile and tools |
| services | non-clustered docker-compose services |
| ssl | PKI certificate tools (deprecated by k8s) |

Find images at [docker hub/instantlinux](https://hub.docker.com/r/instantlinux/). Each image is scanned by [trivy](https://trivy.dev/) to ensure they contain no known CVE vulnerabilities before promotion to Docker Hub.

Find a lot more details about the Kubernetes bare-metal installer in [k8s/README](k8s/README.md).

### Kubernetes capabilities

The cluster-deployment tools here include helm charts and ansible playbooks to spin up bare-metal or VM master/worker nodes, and a Makefile to add several additional features.

* Direct-attached SSD local storage pools
* Non-default namespace with its own service account (full permissions
  within namespace, limited read-only in kube-system namespaces)
* Keycloak for OpenID / OAuth2 user authentication / authorization
* Vaultwarden, a self-hosted Bitwarden-compatible password manager
* Helm4
* Mozilla [sops](https://github.com/mozilla/sops/blob/master/README.rst) with encryption (to keep credentials in local git repo)
* Encryption for internal etcd
* MFA using [Authelia](https://github.com/clems4ever/authelia) and Google Authenticator
* Calico or flannel networking
* ingress-nginx
* Local-volume sync
* Minio object storage with prometheus metrics
* Pod security policies
* Automatic certificate issuing/renewal with Letsencrypt
* Grafana with prometheus-based alerting

### Resource definitions

**Developer infrastructure**

| Service | Version | Notes |
| --- | --- | --- |
| gitea | ** | git repo |
| admin-git | [![](https://img.shields.io/docker/v/instantlinux/git-pull?sort=date)](https://hub.docker.com/r/instantlinux/git-pull "Version badge") | sync git repo across cluster |
| gitea | ** | self-hosted git repo with many github features |
| jira | ** | ticket tracking |
| mariadb-galera | [![](https://img.shields.io/docker/v/instantlinux/mariadb-galera?sort=date)](https://hub.docker.com/r/instantlinux/mariadb-galera "Version badge") | automatic cluster setup|
| nexus | ** | binary repo with docker registry |
| synapse | ** | self-hosted team chat |
| wordpress | ** | |

**Networking and support**

| Service | Version | Notes |
| --- | --- | --- |
| authelia | ** | single-signon multi-factor auth |
| data-sync | [![](https://img.shields.io/docker/v/instantlinux/data-sync?sort=date)](https://hub.docker.com/r/instantlinux/data-sync "Version badge") | poor-man's SAN for persistent storage |
| ddclient | [![](https://img.shields.io/docker/v/instantlinux/ddclient?sort=date)](https://hub.docker.com/r/instantlinux/ddclient "Version badge") | Dynamic DNS client |
| ez-ipupdate | [![](https://img.shields.io/docker/v/instantlinux/ez-ipupdate?sort=date)](https://hub.docker.com/r/instantlinux/ez-ipupdate "Version badge") | Dynamic DNS client |
| fluent-bit | ** | central logging for Kubernetes |
| haproxy-keepalived | [![](https://img.shields.io/docker/v/instantlinux/haproxy-keepalived?sort=date)](https://hub.docker.com/r/instantlinux/haproxy-keepalived "Version badge") | load balancer |
| grafana | ** | monitoring dashboard with prometheus-based alerting |
| guacamole | ** | authenticated remote-desktop server |
| mysqldump | [![](https://img.shields.io/docker/v/instantlinux/mysqldump?sort=date)](https://hub.docker.com/r/instantlinux/mysqldump "Version badge") | per-database alternative to xtrabackup |
| nagios | [![](https://img.shields.io/docker/v/instantlinux/nagios?sort=date)](https://hub.docker.com/r/instantlinux/nagios "Version badge") | Nagios Core v4 for monitoring |
| nagiosql | [![](https://img.shields.io/docker/v/instantlinux/nagiosql?sort=date)](https://hub.docker.com/r/instantlinux/nagiosql "Version badge") | NagiosQL for configuring Nagios Core v4 |
| nextcloud | ** | mobile device sync, like Apple iCloud |
| node-local-dns | ** | caching resolver for reliable pod DNS |
| nut-upsd | [![](https://img.shields.io/docker/v/instantlinux/nut-upsd?sort=date)](https://hub.docker.com/r/instantlinux/nut-upsd "Version badge") | Network UPS Tools |
| openldap | [![](https://img.shields.io/docker/v/instantlinux/openldap?sort=date)](https://hub.docker.com/r/instantlinux/openldap "Version badge") | OpenLDAP authentication server |
| proftpd | [![](https://img.shields.io/docker/v/instantlinux/proftpd?sort=date)](https://hub.docker.com/r/instantlinux/proftpd "Version badge") | FTP server |
| restic | ** | backups |
| rsyslogd | [![](https://img.shields.io/docker/v/instantlinux/rsyslogd?sort=date)](https://hub.docker.com/r/instantlinux/rsyslogd "Version badge") | logger in a 13MB image |
| samba | [![](https://img.shields.io/docker/v/instantlinux/samba?sort=date)](https://hub.docker.com/r/instantlinux/samba "Version badge") | file server |
| samba-dc | [![](https://img.shields.io/docker/v/instantlinux/samba-dc?sort=date)](https://hub.docker.com/r/instantlinux/samba-dc "Version badge") | Active-Directory compatible domain controller |
| [secondshot](https://github.com/instantlinux/secondshot) | [![](https://img.shields.io/docker/v/instantlinux/secondshot?sort=date)](https://hub.docker.com/r/instantlinux/secondshot "Version badge") | rsnapshot-based backups |
| splunk | ** | the free version |
| vaultwarden | ** | BitWarden-compatible self-hosted backend |

**Email**

| Service | Version | Notes |
| --- | --- | --- |
| blacklist | [![](https://img.shields.io/docker/v/instantlinux/blacklist?sort=date)](https://hub.docker.com/r/instantlinux/blacklist "Version badge") | a local rbldnsd for spam control |
| dovecot | [![](https://img.shields.io/docker/v/instantlinux/dovecot?sort=date)](https://hub.docker.com/r/instantlinux/dovecot "Version badge") | imapd server |
| postfix | [![](https://img.shields.io/docker/v/instantlinux/postfix?sort=date)](https://hub.docker.com/r/instantlinux/postfix "Version badge") | compact general-purpose image in 11MB |
| postfix-python | [![](https://img.shields.io/docker/v/instantlinux/postfix-python?sort=date)](https://hub.docker.com/r/instantlinux/postfix-python "Version badge") | postfix with spam-control scripts |
| snappymail | ** | webmail, forked from rainloop imapd-client server |
| spamassassin | [![](https://img.shields.io/docker/v/instantlinux/spamassassin?sort=date)](https://hub.docker.com/r/instantlinux/spamassassin "Version badge") | spam control daemon |

**Entertainment**

| Service | Version | Notes |
| --- | --- | --- |
| davite | [![](https://img.shields.io/docker/v/instantlinux/davite?sort=date)](https://hub.docker.com/r/instantlinux/davite "Version badge") | party-invites manager like eVite |
| mythtv-backend | [![](https://img.shields.io/docker/v/instantlinux/mythtv-backend?sort=date)](https://hub.docker.com/r/instantlinux/mythtv-backend "Version badge") | MythTV backend |
| OwnTone | ** | iTunes server (formerly forked-daapd) |
| weewx | [![](https://img.shields.io/docker/v/instantlinux/weewx?sort=date)](https://hub.docker.com/r/instantlinux/weewx "Version badge") | Weather station software (Davis VantagePro2 etc.) |

### Credits

Thank you to the following contributors!

* [Mike Neir](https://github.com/d0ct0rvenkman)
* [Chad Hedstrom](https://github.com/Hadlock) - [personal site](http://nearlydeaf.com/)
* [Sean Mollet](https://github.com/SeanMollet)
* [Juan Manuel Carrillo Moreno](https://github.com/inetshell) - [personal site](https://wiki.inetshell.mx/)
* [nicxvan]( https://github.com/nicxvan)
* [Frank Riley](https://github.com/fhriley)
* [Devin Bayer](https://github.com/akvadrako)
* [Daniel Muller](https://github.com/DanielMuller)
* [Brian Hechinger](https://github.com/bhechinger)
* [David Powers](https://github.com/dapowers87)
* [Alberto Galera](https://github.com/agalera)
* [Andrew Eacott](https://github.com/andreweacott)

Contents created 2017-26 under [Apache 2.0 License](https://www.apache.org/licenses/LICENSE-2.0) by Rich Braun.
