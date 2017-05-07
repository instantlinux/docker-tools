HOSTS = mckinley vinson denali
SERVICES = etcd mt-daapd weewx

default: $(HOST)

mckinley: etcd mt-daapd weewx
vinson: etcd mt-daapd
denali: etcd

$(SERVICES)::
	@echo Starting $@
	cd $@ ; docker-compose up -d
