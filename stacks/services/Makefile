# Ad-hoc services
#   These are containers run without Kubernetes

HOST = $(shell hostname -s)
REGISTRY_URI ?= nexus.instantlinux.net
SERVICES = haproxy-keepalived nut-upsd weewx

default: $(HOST)

mckinley: nut-upsd weewx
denali: nut-upsd
k2: nagios haproxy-keepalived

$(SERVICES)::
	@echo Starting $@
	@if [ $@ != "etcd" ] && [ $@ != 'ntpd' ] && \
            [ $@ != haproxy-keepalived ]; then \
           docker pull $(REGISTRY_URI)/$@:latest; \
        fi
	cd $@ ; docker-compose up -d

nagios::
	@echo Starting $@
	docker pull $(REGISTRY_URI)/nagiosql:latest; \
	cd $@ ; docker-compose up -d
