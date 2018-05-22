# Configure security and node labels for sync hosts
#
# Usage:
#  PRIMARY=host1 PEER=host2 make

include ../../lib/build/Makefile.docker_image

TEMPDIR := $(shell mktemp -d -t tempdir.XXXXX)
SHARED_ROOT = /var/lib/docker/share
KEY_NAME ?= swarm-sync
PUBENV = .docker/$(KEY_NAME).pub.env
NRPE_PATH = /etc/nrpe.d

default: $(HOME)/$(PUBENV) $(SHARED_ROOT) label_nodes

$(HOME)/.docker/$(KEY_NAME).pub.env:
	@bash -c "cd $(TEMPDIR) && umask 077 && \
	 ssh-keygen -b 2048 -f $(KEY_NAME) -N '' -q && \
	 echo -n 'SYNC_SSHKEY=no-pty,no-agent-forwarding,no-X11-forwarding,no-port-forwarding,command=\"/usr/bin/unison -server\" ' > $(HOME)/$(PUBENV) && \
	 cat $(KEY_NAME).pub >> $(HOME)/$(PUBENV) && \
	 docker secret create $(KEY_NAME)_sshkey $(KEY_NAME) || rm $(HOME)/$(PUBENV)"
	@rm -r $(TEMPDIR)
	@echo "For ssh keypair, see $(PUBENV)"
	@docker secret inspect $(KEY_NAME)_sshkey

label_nodes:
	@docker node update --label-add swarm-sync=primary $(PRIMARY)
	@docker node update --label-add swarm-sync-member=true $(PRIMARY)
	@docker node update --label-add mail-sync-member=true $(PRIMARY)
	@docker node update --label-add swarm-sync=peer $(PEER)
	@docker node update --label-add swarm-sync-member=true $(PEER)
	@docker node update --label-add mail-sync-member=true $(PRIMARY)
	@echo "Nodes labeled, use node.labels.swarm-sync-member == true"

nagios_nrpe:
	@echo "Installing nrpe check"
	@sudo cp src/nagios-nrpe-swarm-sync.cfg $(NRPE_PATH)/swarm-sync.cfg

$(SHARED_ROOT):
	sudo mkdir $(SHARED_ROOT)
