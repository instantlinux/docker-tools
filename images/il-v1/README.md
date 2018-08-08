## il-v1

Front-end of my 2011-vintage InstantLinux v1, a LAMP application for
server administration. It's written in CakePHP version 1.3. This
docker build pulls from private repos (sorry, I don't plan to release
them) but I'm making it public to illustrate one of the big challenges
of "Dockerizing" legacy apps.

### Usage
Set the variables as defined below, and run the docker-compose stack. The
service will be visible as http://host:port; it's intended to run behind
nginx SSL reverse-proxy.

### Variables

Variable | Default | Description
-------- | ------- | -----------
DB_HOST | db00 | db host
DB_NAME | instantlinux |db name
DB_PASSWD_SECRET | il-v1-db-password | name of secret (see below)
DB_USER | cakephp | db username
FQDN | instantlinux.domain.com | fqdn of front-end's vhost
REMOTES | host.domain.com | hosts for ssh-keyscan by capi user
SECRET_SSH_CAPI | il_capi_sshkey | name of secret
SECRET_SSH_PROXY | il_proxy_sshkey | name of secret
SECRET_ILCLIENT_PASSWORD | ilclient-password | name of secret
SECRET_ILINUX_PASSWORD | ilinux-password | name of secret
SECRET_MYSQL_BACKUP | mysql-backup | name of secret
TZ | UTC | time zone

### Secrets
Name | Description
---- | -----------
il_capi_sshkey | ssh private key for capistrano
il_proxy_sshkey | ssh private key for proxy
il-v1-db-password | password to the MySQL database
ilclient-password | REST api client
ilinux-password | 
mysql-backup | mysql db backup user

### Notes
This is the first time I've crafted a release-packaging script for this application; it illustrates an (almost) worst-case scenario of Dockerizing a chaotic mess of scripts and source-code repos that was never properly organized. My approach to software deployment has fundamentally changed over the 6 years since I developed this application. Abandoning both puppet and chef, and embracing docker/jenkins in their place, has led to a far more straighforward methodology for all my other images.

[![](https://images.microbadger.com/badges/license/instantlinux/il-v1.svg)](https://microbadger.com/images/instantlinux/il-v1 "License badge")
