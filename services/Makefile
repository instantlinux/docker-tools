HOSTS = mckinley vinson denali
SERVICES = etcd mt-daapd weewx
REGISTRY := dockerhub.instantlinux.net:5000
ADV = node1
INSTANCE = etc00

ifeq ($(HOST), denali)
 ADV = node2
 INSTANCE = etc01
endif
ifeq ($(HOST), vinson)
 ADV = node3
 INSTANCE = etc02
endif

default: $(HOST)

mckinley: etcd mt-daapd weewx
vinson: etcd mt-daapd
denali: etcd

$(SERVICES)::
	@echo Starting $@
	@if [ $@ != "etcd" ]; then docker pull $(REGISTRY)/$@:latest; fi
	cd $@ ; INSTANCE=$(INSTANCE) ADV=$(ADV) docker-compose up -d
