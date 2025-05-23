# INITIAL SETUP
# -------------
#
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

# AFTER INITIAL SETUP
# -------------------
#
# Once you have your first namespace set up, this Makefile can handle additional
# maintenance tasks:
#
# 1) Adding a new namespace
#   K8S_NAMESPACE=<new> make namespace_config
#   sops -d secrets/regcred.yml | envsubst | kubectl create \
#     -n $K8S_NAMESPACE --context=sudo -f -
# 2) Adding a new node
#   export K8S_WORKER_COUNT=$newcount
#   make node_labels
#   K8S_NODES=$node make persistent
#   NODE=$node make persistent_dirs
#
# Always use fqdn for NODE names.

ACTION          ?= apply
CLUSTER         ?= kubernetes
ADMIN_CTX       ?= --context=kubernetes-admin@$(CLUSTER)
VERSION_SOPS    ?= 3.2.0
SOPS_SHA        ?= dd12ccaeef8ed72692023fb081d63538e4a0e458e29dc21b421b38ff3e320a74
STACKS = $(basename $(wildcard *.yaml))

include Makefile.vars
include Makefile.versions
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
	  envsubst < $@.yaml | kubectl $(ACTION) --context=sudo \
	  --namespace $(K8S_NAMESPACE) -f -

##########
# Installation
##########
.PHONY: envsubst imports install namespace_config node_labels \
	persistent remote_volumes secrets sops untaint_master

IMPORTS      = cert-manager flannel
INSTALL_YAML = $(basename $(wildcard install/*.yaml)) \
          $(addprefix imports/, $(IMPORTS))
VOLUMES_YAML = $(basename $(wildcard volumes/*.yaml))

install: install/admin-user cluster_network \
	install/local-storage storage_localdefault imports \
	install_imports namespace_config install/prometheus-rbac \
	install/k8s-backup install/logspout remote_volumes \
	sops data-sync-ssh persistent secrets install/ingress-nginx \
	install/cert-manager

namespace_config: install/namespace install/limits install/namespace-user \
	secrets/regcred

untaint_master:
	@echo -e '** Allowing workload on master risks admin-cert security compromise **\n'
	kubectl $(ADMIN_CTX) taint nodes $(NODE) node-role.kubernetes.io/master-

node_labels:
	./scripts/node_labels.sh

data-sync-ssh:
	if ! (kubectl get secrets -n $(K8S_NAMESPACE) | grep -q "^$@ "); then \
	  cd ../images/data-sync && make $@; fi

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

ifeq ($(shell uname -s),Darwin)
envsubst: /usr/local/bin/envsubst
else
envsubst: /usr/bin/envsubst
endif

/usr/local/bin/envsubst:
	brew install gettext && brew link --force gettext

##########
# Storage
##########
persistent:
	./scripts/persistent.sh $(K8S_NODES)

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

imports/cert-manager.yaml: imports/cert-manager-$(VERSION_CERT_MANAGER).yaml
	ln -s $(notdir $<) $@
imports/cert-manager-$(VERSION_CERT_MANAGER).yaml:
	curl -sLo $@ https://github.com/jetstack/cert-manager/releases/download/v$(VERSION_CERT_MANAGER)/cert-manager.yaml

# TODO: remove this once it's clear the above works without helm
# When updating, do "helm delete --purge cert-manager" first
cert-manager-helm: helm_install
	helm install stable/cert-manager \
	 --name cert-manager --namespace cert-manager \
	 --set ingressShim.defaultIssuerName=letsencrypt-prod \
	 --set ingressShim.defaultIssuerKind=ClusterIssuer \
	 --set webhook.enabled=false \
	 --kube-context=sudo
	kubectl label namespace cert-manager --context=sudo \
	 certmanager.k8s.io/disable-validation=true

##########
# Add-ons
##########
imports: $(foreach file,$(IMPORTS),imports/$(file).yaml)
install_imports: $(foreach file, $(IMPORTS), imports/$(file))

imports/kube-state-metrics: imports/kube-state-metrics-$(VERSION_METRICS)
	ln -s $(notdir $<) $@
imports/kube-state-metrics-$(VERSION_METRICS):
	git clone --dept 1 --branch v$(VERSION_METRICS) \
	 https://github.com/kubernetes/kube-state-metrics \
	 imports/kube-state-metrics-$(VERSION_METRICS)
install_metrics: imports/kube-state-metrics
	kubectl apply --context=sudo -k $</examples/standard

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
