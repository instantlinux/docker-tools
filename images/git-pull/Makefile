TEMPDIR := $(shell mktemp -d)
PUBKEY := /var/adm/admin/tls/git-deploy.pub

default:
	make $(PUBKEY)

$(PUBKEY):
	@bash -c "cd $(TEMPDIR) && umask 077 && \
	 ssh-keygen -b 2048 -f git-deploy -N '' -q && \
         cp git-deploy.pub $(PUBKEY) && \
	 docker secret create git-deploy_sshkey git-deploy || rm $(PUBKEY)"
	@rm -r $(TEMPDIR)
	@echo "For ssh keypair, see $(PUBKEY)"
	@docker secret inspect git-deploy_sshkey

include ../../lib/build/Makefile.docker_image
