# Configure security and node labels for sync hosts
#
# Usage:
#  PRIMARY=host1 PEER=host2 make

TEMPDIR := $(shell mktemp -d -t tempdir.XXXXX)
SHARED_ROOT = /var/lib/docker/share
PUBENV = .docker/swarm-sync.pub.env
PEMENV = .docker/swarm-sync.pem.env

default: $(HOME)/$(PUBENV) $(SHARED_ROOT) label_nodes

$(HOME)/.docker/swarm-sync.pub.env:
	@bash -c "cd $(TEMPDIR) && \
	 ssh-keygen -b 2048 -f swarm-sync -N '' -q && \
	 echo -n 'SYNC_SSHKEY=no-pty,no-agent-forwarding,no-X11-forwarding,no-port-forwarding,command=\"/usr/bin/unison -server\" ' > $(HOME)/$(PUBENV) && \
	 cat swarm-sync.pub >> $(HOME)/$(PUBENV) && \
	 echo -n 'SYNC_SSHPEM=' > pem && \
	 cat swarm-sync >> pem && \
	 cat pem | tr '\n' ',' > $(HOME)/$(PEMENV)"
	@rm -r $(TEMPDIR)
	@echo "Generated ssh keypair"

	# TODO: install 17.03 so I can use secrets in compose 3.1
	# docker secret create swarm-sync-sshkey swarm-sync"

label_nodes:
	@docker node update --label-add swarm-sync=primary $(PRIMARY)
	@docker node update --label-add swarm-sync-member=true $(PRIMARY)
	@docker node update --label-add swarm-sync=peer $(PEER)
	@docker node update --label-add swarm-sync-member=true $(PEER)
	@echo "Nodes labeled, use node.labels.swarm-sync-member == true"

$(SHARED_ROOT):
	sudo mkdir $(SHARED_ROOT)
clean:
	@find . -name '*~' -exec rm {} \;
