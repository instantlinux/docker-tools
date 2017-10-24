HOST = $(shell hostname -s)
HOSTS = mckinley vinson denali
REGISTRY_URI ?= nexus.instantlinux.net
SERVICES = dhcpd-dns-pxe etcd mt-daapd mythtv-backend ntpd nut-upsd weewx

# Before starting etcd, see notes in etcd/docker-compose.yml.

ADV = node1
ifeq ($(HOST), denali)
 ADV = node2
endif
ifeq ($(HOST), vinson)
 ADV = node3
endif

default: $(HOST)

mckinley: dhcpd-dns-pxe etcd mt-daapd mythtv-backend ntpd nut-upsd weewx
vinson: dhcpd-dns-pxe etcd mt-daapd
denali: dhcpd-dns-pxe etcd nut-upsd

$(SERVICES)::
	@echo Starting $@
	@if [ $@ != "etcd" ] && [ $@ != 'ntpd' ]; then \
           docker pull $(REGISTRY_URI)/$@:latest; \
        fi
	cd $@ ; ADV=$(ADV) docker-compose up -d
