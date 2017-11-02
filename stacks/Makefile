MAKEFLAGS += -rR
STACKS = $(basename $(wildcard *.yml))
DEPLOY = $(STACKS:%=.deploy/%)

db00: CLUSTER_NAME = db00

default: $(DEPLOY)

.deploy/%: %.yml
	@echo Deploying $(@F)
	@mkdir -p .deploy
	CLUSTER_NAME=$(CLUSTER_NAME) \
	  docker stack deploy --with-registry-auth -c $(@F).yml $(@F)
	@touch .deploy/$(@F)

admin: .deploy/admin
artifactory: .deploy/artifactory
authelia: .deploy/authelia
blacklist: .deploy/blacklist
cloud: .deploy/cloud
crashplan: .deploy/crashplan
davite: .deploy/davite
db00: .deploy/db00
docs: .deploy/docs
dovecot: .deploy/dovecot
ez-ipupdate: .deploy/ez-ipupdate
gitlab: .deploy/gitlab
git-dump: .deploy/git-dump
guacamole: .deploy/guacamole
jenkins: .deploy/jenkins
jira: .deploy/jira
logspout: .deploy/logspout
mariadb: .deploy/mariadb
mysqldump: .deploy/mysqldump
nexus: .deploy/nexus
portainer: .deploy/portainer
postfix: .deploy/postfix
proftpd: .deploy/proftpd
registry: .deploy/registry
rsyslogd: .deploy/rsyslogd
spamassassin: .deploy/spamassassin
splunk: .deploy/splunk
squirrelmail: .deploy/squirrelmail
swarm-sync: .deploy/swarm-sync
swarm-sync-2: .deploy/swarm-sync-2
udp-nginx-proxy: .deploy/udp-nginx-proxy
wordpress-ci: .deploy/wordpress-ci
wordpress-il: .deploy/wordpress-il
www00: .deploy/www00
wwwext: .deploy/wwwext
wx-nginx: .deploy/wx-nginx
vsftpd: .deploy/vsftpd

net_create::
	docker network create dbcluster --driver overlay $(LABELS)

# TODO: does not work
%: .deploy/%
