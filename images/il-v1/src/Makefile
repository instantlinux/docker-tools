DIR=$(PWD)
default: cake-from-manifest.tar.gz

cake-from-manifest.tar.gz: $(DIR)/cake-2017.manifest
	cd /var/www/htdocs/il/app ; \
	tar cvzf $(DIR)/$@ $(shell cat $<) --exclude-vcs --exclude=debug_kit
