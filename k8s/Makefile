#
# Usage:
#   make <service>
#   make persistent volumes
#   ACTION=delete make <service>
#   NODE=<host> make persistent_dirs
#
# Note - create node persistent_dirs before persistent volumes

ACTION ?= apply
IMPORTS = dashboard flannel ingress-nginx ingress-nginx-nodeport
NODES  ?= $(K8S_NODES)
VOLUMES = $(basename $(wildcard volumes/*.yaml))
VOL_NUM = 0030
STACKS  = $(basename $(wildcard *.yaml)) \
          $(addprefix imports/, $(IMPORTS)) $(VOLUMES)

ifeq ($(ACTION), delete)
  NOTICE=Removing
else
  NOTICE=Deploying
endif

all: imports $(STACKS)

$(STACKS)::
	@echo --$(NOTICE) $@ --
	@SERVICE_NAME=$(@F) \
	  envsubst < $@.yaml | kubectl $(ACTION) -f -

imports: $(foreach file,$(IMPORTS),imports/$(file).yaml)
volumes: persistent $(VOLUMES)
persistent:
	@$(eval vols = $(shell bash -c 'echo pv{0001..$(VOL_NUM)}'))
	for node in $(NODES); do \
	  for vol in ${vols}; do \
	    VOLUME_NAME=$${vol} NODENAME=$${node} make persistent-volumes; \
	  done; \
	done

persistent_dirs::
	ssh $(NODE) sudo 'mkdir -p $$(echo \
	  /var/lib/docker/k8s-volumes/pv{0001..$(VOL_NUM)})'

imports/dashboard.yaml:
	mkdir -p imports
	curl -sLo $@ https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml

imports/flannel.yaml:
	curl -sLo $@ https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

imports/ingress-nginx.yaml:
	curl -sLo $@ https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/mandatory.yaml

imports/ingress-nginx-nodeport.yaml:
	curl -sLo $@ https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/provider/baremetal/service-nodeport.yaml
