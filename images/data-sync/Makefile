# Generate ssh keypair for kubernetes
#
# Usage:
#  HOST1=host1 HOST2=host2 make

include ../../lib/build/Makefile.docker_image

K8S_NAMESPACE ?= default
NRPE_PATH      = /etc/nrpe.d
SHARE_PATH    ?= /var/lib/docker/share
TEMPDIR       := $(shell mktemp -d -t tempdir.XXXXX)

.PHONY: data-sync-ssh
default: data-sync-ssh $(SHARED_ROOT) label_nodes

data-sync-ssh:
	bash -c "cd $(TEMPDIR) && umask 077 && \
	 ssh-keygen -b 2048 -f sshkey1 -N '' -q && \
	 cat sshkey1.pub >> pubkey1 && \
	 ssh-keygen -b 2048 -f sshkey2 -N '' -q && \
	 cat sshkey2.pub >> pubkey2"
	kubectl create secret generic --namespace $(K8S_NAMESPACE) \
	  --from-file=$(TEMPDIR)/sshkey1 \
	  --from-file=$(TEMPDIR)/pubkey1 \
	  --from-file=$(TEMPDIR)/sshkey2 \
	  --from-file=$(TEMPDIR)/pubkey2 \
	  $@
	@rm -r $(TEMPDIR)

label_nodes:
	kubectl label node --overwrite $HOST1 service.data-sync=allow
	kubectl label node --overwrite $HOST2 service.data-sync=allow

nagios_nrpe:
	@echo "Installing nrpe check"
	@sudo cp src/nagios-nrpe-data-sync.cfg $(NRPE_PATH)/data-sync.cfg

$(SHARED_ROOT):
	sudo mkdir $(SHARED_ROOT)
