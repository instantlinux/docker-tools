# Step 2: configure kubernetes master resources
#
# This is the second step of three in kubernetes installation--picks up where
# kubeadm leaves off, tightening security and setting up the cluster for
# routine "user-level" administration of a namespace so services can
# be managed without distributing the kubernetes-admin client key.
#
# Step 1: cd ../ansible; make k8s-master
#
# Usage - after step 1, review Makefile.vars, set your override vars, then do
#   make install
#   make storage_localdefault
#   for node in kube1.domain kube2.domain <etc>; do
#     NODE=$node make persistent_dirs
#   done
#   (run step 3: ansible playbook k8s-node)
#   make node_labels
#
# If setting up MythTV, mount the main storage on each of two nodes as
#     /var/lib/docker/k8s-volumes/mythtv and invoke:
#   NODE=kube1.domain make mythtv_vol
#   NODE=kube2.domain make mythtv_vol
#
# If running a single-node minikube-like installation, do this:
#   NODE=(master).domain make untaint_master
#
# If running a cluster, proceed to step 3. Look for k8s-node playbook in the
#   ansible directory.
#
# Then for routine administration of services defined as resource YAML
# files here in this directory:
#   make <service>
#   ACTION=delete make <service>
#
# Storage volumes are direct-attached of type 'local-storage' under a specified
# path. Two pools are generated for dynamic provisioning, and the following
# three are set to specific named locations for ease of administration:
#
#   admin - read-only continuously synchronized config data per service
#   backup - use for centralizing backup content per service
#   share - read-write continuously synchronized across cluster
#
# Define additional large storage volumes using the volumes role of ansible
# and set an environment variable LOCAL_VOLUMES to generate k8s pvs for
# each node.

ACTION          ?= apply
CLUSTER         ?= kubernetes
ADMIN_CTX       ?= --context=kubernetes-admin@$(CLUSTER)
VERSION_HELM    ?= 2.11.0
VERSION_METRICS ?= v0.3.1
VERSION_SOPS    ?= 3.2.0
SOPS_SHA        ?= dd12ccaeef8ed72692023fb081d63538e4a0e458e29dc21b421b38ff3e320a74
STACKS = $(basename $(wildcard *.yaml))

include Makefile.vars
include Makefile.instances

ifeq ($(ACTION), delete)
  NOTICE=Removing
else
  NOTICE=Deploying
endif

all: imports $(INSTALL_YAML) $(STACKS)

$(STACKS)::
	@echo --$(NOTICE) $@--
	@SERVICE_NAME=$(@F) \
	  envsubst < $@.yaml | kubectl $(ACTION) --namespace $(K8S_NAMESPACE) -f -

##########
# Installation
##########
.PHONY: imports install install_metrics node_labels persistent remote_volumes \
	secrets sops untaint_master

IMPORTS      = calico calico-etcd dashboard flannel ingress-nginx
INSTALL_YAML = $(basename $(wildcard install/*.yaml)) \
          $(addprefix imports/, $(IMPORTS))
VOLUMES_YAML = $(basename $(wildcard volumes/*.yaml))

install: install/admin-user install/namespace install/limits \
	cluster_network install/namespace-user install/cert-manager \
	install/podsecurity storage_localdefault imports install_imports \
	install/gitlab-rbac install/k8s-backup install/local-storage \
	install/logspout install_metrics extend_dashboard_ttl remote_volumes \
	sops secrets data-sync-ssh ~/.kube/config.conf persistent

untaint_master:
	@echo -e '** Allowing workload on master risks admin-cert security compromise **\n'
	kubectl $(ADMIN_CTX) taint nodes $(NODE) node-role.kubernetes.io/master-

node_labels:
	./scripts/node_labels.sh

data-sync-ssh:
	@cd ../images/data-sync && make data-sync || echo Already exists/ignored

~/.kube/config.conf:
	@./scripts/kube-conf-gen.sh ~/.kube/admin.conf $@ $(ADMIN_CTX) $(CLUSTER)
	@echo -e \\n'Admin and user context configurations installed in ~/.kube'
	@echo -e \\n'***** Save a copy of these files and keep secure !!!! *****'
	@echo -e \\n'***** Do not lose or redistribute admin.conf or admin-user.* !! *****'\\n

remote_volumes: $(VOLUMES_YAML)

$(INSTALL_YAML) $(VOLUMES_YAML)::
	@echo --$(NOTICE) $@--
	@SERVICE_NAME=$(@F) \
	  envsubst < $@.yaml | kubectl $(ADMIN_CTX) $(ACTION) -f -

##########
# Storage
##########
persistent:
	./scripts/persistent.sh $(NODES)

persistent_dirs:
	ssh "$(NODE)" sudo 'mkdir -p $$(echo \
	  $(K8S_VOLUMES_PATH)/pool-s/pv-$(POOL_SIZE_SMALL)-{0001..$(POOL_NUM_SMALL)} \
	  $(K8S_VOLUMES_PATH)/pool-m/pv-$(POOL_SIZE_MEDIUM)-{0001..$(POOL_NUM_MEDIUM)}) \
	  $(K8S_VOLUMES_PATH)/{$(shell echo $(NAMED_VOLUMES)|tr " " ,)}'
	ssh "$(NODE)" sudo chmod 700 $(K8S_VOLUMES_PATH)/pool-[sm]

mythtv_vol:
	NAME=$(NODE)-mythtv VOLUME_ROOT=$(K8S_VOLUMES_PATH)/mythtv \
	VOLUME_ID=$(shell uuidgen | cut -d - -f 1) \
	VOLUME_SIZE=$(MYTHTV_VOL_SIZE) NODENAME=$(NODE) GROUP=mythtv \
	make install/persistent-item

storage_localdefault:
	kubectl $(ADMIN_CTX) patch storageclass local-storage -p \
	  '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

##########
# etcd
##########
imports/etcd-token:
	@-kubectl delete secret $(@F)
	(cd imports && \
	 basename \
	  `curl -s 'https://discovery.etcd.io/new?size=$(ETCD_NUM_NODES)'` \
	  > $(@F) && \
	 kubectl create secret generic $(@F) --from-file $(@F))

##########
# Helm
##########
include Makefile.helm

##########
# Network
##########
include Makefile.network

##########
# Secrets
##########
include Makefile.sops

##########
# cert-manager
##########

# TODO: make this work without helm, while tracking doc problem:
#  https://github.com/jetstack/cert-manager/issues/1151
cert-manager: helm_install
	helm install --name cert-manager --namespace kube-system \
	 stable/cert-manager --kube-context=sudo

##########
# Add-ons
##########
imports: $(foreach file,$(IMPORTS),imports/$(file).yaml)
install_imports: $(foreach file, $(IMPORTS), imports/$(file))

# extend annoying default 15-minute timeout
# (temporarily) disable metrics healthcheck
# TODO: re-enable metric-client-check when metrics-server is working
#  See https://github.com/kubernetes/dashboard/issues/2986
.PHONY: extend_dashboard_ttl
extend_dashboard_ttl:
	kubectl $(ADMIN_CTX) patch deployment kubernetes-dashboard --namespace kube-system \
	  --patch='$(shell cat install/dashboard-patch.json)'

imports/dashboard.yaml:
	mkdir -p imports
	curl -sLo $@ https://raw.githubusercontent.com/kubernetes/dashboard/v$(VERSION_DASHBOARD)/src/deploy/recommended/kubernetes-dashboard.yaml

imports/metrics-$(VERSION_METRICS):
	mkdir -p imports
	git clone --depth=1 --branch=$(VERSION_METRICS) \
	 https://github.com/kubernetes-incubator/metrics-server.git $@

install_metrics: imports/metrics-$(VERSION_METRICS)
	kubectl $(ADMIN_CTX) $(ACTION) -f \
	  imports/metrics-$(VERSION_METRICS)/deploy/1.8+/

imports/ingress-nginx.yaml:
	curl -sLo $@ https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/mandatory.yaml

imports/traefik-prom.yaml:
	curl -sLo $@ https://raw.githubusercontent.com/mateobur/prometheus-monitoring-guide/master/traefik-prom.yaml

# As of Jan-2019, the helm chart for etcd doesn't reliably construct multi-node
# cluster, just use 'make etcd' rather than 'make etcd_chart'
etcd_chart:
	helm install --name etcd --namespace $(K8S_NAMESPACE) \
	  --kube-context=kubernetes-admin@$(CLUSTER) \
	  bitnami/etcd --set auth.rbac.enabled=false
	sleep 30
	kubectl scale statefulset etcd-etcd --namespace=$(K8S_NAMESPACE) --replicas=3
