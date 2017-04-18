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
	 docker secret create swarm-sync_sshkey swarm-sync"
	@rm -r $(TEMPDIR)
	@echo "Generated ssh keypair"

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
