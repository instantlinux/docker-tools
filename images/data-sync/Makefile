# Generate ssh keypair for kubernetes
#
# Usage:
#  HOST1=host1 HOST2=host2 make

include ../../lib/build/Makefile.docker_image

K8S_NAMESPACE ?= default
KEY_NAME      ?= data-sync
NRPE_PATH      = /etc/nrpe.d
SHARE_PATH    ?= /var/lib/docker/share
TEMPDIR       := $(shell mktemp -d -t tempdir.XXXXX)

default: $(KEY_NAME) $(SHARED_ROOT) label_nodes

$(KEY_NAME):
	@bash -c "cd $(TEMPDIR) && umask 077 && \
	 ssh-keygen -b 2048 -f $(KEY_NAME) -N '' -q && \
	 echo -n 'no-pty,no-agent-forwarding,no-X11-forwarding,no-port-forwarding,command=\"/usr/bin/unison -server\" ' > sync-sshkey && \
	 cat $(KEY_NAME).pub >> sync-sshkey"
	kubectl create configmap data-sync --namespace $(K8S_NAMESPACE) --from-file=$(TEMPDIR)/sync-sshkey
	kubectl create secret generic --namespace $(K8S_NAMESPACE) --from-file=$(TEMPDIR)/$(KEY_NAME) $(KEY_NAME)-sshkey
	@rm -r $(TEMPDIR)

label_nodes:
	kubectl label node --overwrite $HOST1 service.data-sync=allow
	kubectl label node --overwrite $HOST2 service.data-sync=allow

nagios_nrpe:
	@echo "Installing nrpe check"
	@sudo cp src/nagios-nrpe-data-sync.cfg $(NRPE_PATH)/data-sync.cfg

$(SHARED_ROOT):
	sudo mkdir $(SHARED_ROOT)
