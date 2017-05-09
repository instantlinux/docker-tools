HOSTS = mckinley vinson denali
SERVICES = etcd mt-daapd weewx
REGISTRY := dockerhub.instantlinux.net:5000

default: $(HOST)

mckinley: etcd mt-daapd weewx
vinson: etcd mt-daapd
denali: etcd

$(SERVICES)::
	@echo Starting $@
	@docker pull $(REGISTRY)/$@:latest
	cd $@ ; docker-compose up -d
