# Ad-hoc services
#   These are containers run without Kubernetes
#
# Usage:
#   # Make sure to set up SHARE_PATH env
#   make <hostname>

HOST = $(shell hostname -s)
REGISTRY_URI ?= nexus.instantlinux.net
SERVICES = garage haproxy-keepalived mythtv-backend nut-upsd restic-server
ifeq ($(shell test -d /var/adm/admin/services && echo 1),1)
  export ADMIN_PATH=/var/adm/admin/services
endif

# Versions - for images launched by docker-compose
export    VERSION_GARAGE ?= v2.3.0
export VERSION_GAR_WEBUI ?= 1.1.0
export     VERSION_HA_KA ?= 3.4.4-alpine-2.3.4-r2
export     VERSION_KC_DB ?= 10
export  VERSION_KEYCLOAK ?= 26.5.2
export    VERSION_NAGIOS ?= 4.5.14-2.5
# 3.5.0 held back - PEAR: NOT AVAILABLE
export  VERSION_NAGIOSQL ?= 3.4.1-4.4.6
export     VERSION_NGINX ?= 1.29.5-alpine
export  VERSION_NUT_UPSD ?= 2.8.5-r1
export    VERSION_RESTIC ?= 0.14.0

default: $(HOST)

cumbre: haproxy-keepalived nut-upsd
k2: haproxy-keepalived keycloak nagios restic-server

$(SERVICES)::
	@echo Starting $@
	cd $@ ; docker compose up -d

keycloak::
	@echo Starting $@
	@cd $@ ; KEYCLOAK_DB_PASSWORD=$(shell cat \
	 /var/adm/secrets/keycloak-db-password) docker compose up -d
