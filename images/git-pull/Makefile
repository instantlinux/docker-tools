TEMPDIR := $(shell mktemp -d)
PUBKEY := /var/adm/admin/tls/git-deploy.pub

default:
	make $(PUBKEY)

$(PUBKEY):
	@bash -c "cd $(TEMPDIR) && umask 077 && \
	 ssh-keygen -b 2048 -f git-deploy-sshkey -N '' -q && \
         cp git-deploy-sshkey.pub $(PUBKEY) && \
	 docker secret create git-deploy-sshkey git-deploy-sshkey || rm $(PUBKEY)"
	kubectl create secret generic git-deploy-sshkey \
	  --from-file=./git-deploy-sshkey --namespace=$(K8S_NAMESPACE)
	@rm -r $(TEMPDIR)
	@echo "For ssh keypair, see $(PUBKEY)"
	@docker secret inspect git-deploy-sshkey

include ../../lib/build/Makefile.docker_image
