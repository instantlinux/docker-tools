# Ad-hoc services
#   These are containers run without Kubernetes
#
# Usage:
#   # Make sure to set up SHARE_PATH env
#   make <hostname>

HOST = $(shell hostname -s)
REGISTRY_URI ?= nexus.instantlinux.net
SERVICES = haproxy-keepalived mythtv-backend nut-upsd restic-server
ifeq ($(shell test -d /var/adm/admin/services && echo 1),1)
  export ADMIN_PATH=/var/adm/admin/services
endif

default: $(HOST)

cumbre: haproxy-keepalived nut-upsd
k2: nagios haproxy-keepalived keycloak restic-server

$(SERVICES)::
	@echo Starting $@
	cd $@ ; docker-compose up -d

keycloak::
	@echo Starting $@
	@cd $@ ; KEYCLOAK_DB_PASSWORD=$(shell cat \
	 /var/adm/secrets/keycloak-db-password) docker-compose up -d

nagios::
	@echo Starting $@
	docker pull $(REGISTRY_URI)/nagiosql:latest; \
	cd $@ ; docker-compose up -d
