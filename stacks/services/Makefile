# Ad-hoc services
#   These are containers run without Kubernetes
#
# Usage:
#   # Make sure to set up DOMAIN/SHARE_PATH env
#   make <hostname>

HOST = $(shell hostname -s)
REGISTRY_URI ?= nexus.instantlinux.net
SERVICES = haproxy-keepalived nut-upsd restic-server
ifeq ($(shell test -d /var/adm/admin/services && echo 1),1)
  export ADMIN_PATH=/var/adm/admin/services
endif

default: $(HOST)

cumbre: haproxy-keepalived nut-upsd
k2: nagios haproxy-keepalived restic-server

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
