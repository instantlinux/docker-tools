MAKEFLAGS += -rR
STACKS = $(basename $(wildcard *.yml))
DEPLOY = $(STACKS:%=.deploy/%)

db00: CLUSTER_NAME = db00
db00: TCP_PORT = $(PORT_DB00)

default: $(DEPLOY)

.deploy/%: %.yml
	@echo Deploying $(@F)
	@mkdir -p .deploy
	TCP_PORT=$(TCP_PORT) CLUSTER_NAME=$(CLUSTER_NAME) \
	  docker stack deploy -c $(@F).yml $(@F)
	@touch .deploy/$(@F)

admin: .deploy/admin
db00: .deploy/db00
ez-ipupdate: .deploy/ez-ipupdate
gitlab: .deploy/gitlab
jenkins: .deploy/jenkins
jira: .deploy/jira
logspout: .deploy/logspout
mariadb: .deploy/mariadb
postfix: .deploy/postfix
registry: .deploy/registry
spamassassin: .deploy/spamassassin
swarm-sync: .deploy/swarm-sync
www00: .deploy/www00

net_create::
	docker network create dbcluster --driver overlay $(LABELS)

xtradb: xtradb-bootstrap-2node.yml
	@echo Deploying $(@F)
	@mkdir -p .deploy
	TCP_PORT=$(TCP_PORT) CLUSTER_NAME=$(CLUSTER_NAME) \
	  docker stack deploy -c xtradb-bootstrap-2node.yml $(@F)
	@touch .deploy/$(@F)

# TODO: does not work
%: .deploy/%
