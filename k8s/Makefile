# Step 2: configure kubernetes master resources
#
# This is the second step of three in kubernetes installation--picks up where
# kubeadm leaves off, tightening security and setting up the cluster for
# routine "user-level" administration of a namespace so services can
# be managed without distributing the kubernetes-admin client key.
#
# Usage - after invoking ansible playbook k8s-master, set up in this sequence:
#   make install
#   make storage_localdefault
#   for node in kube1.domain kube2.domain <etc>; do
#     NODE=$node make persistent_dirs
#   done
#   (run step 3: ansible playbook k8s-node)
#   make node_labels
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

ACTION         ?= apply
CLUSTER        ?= kubernetes
ADMIN_CTX      ?= --context=kubernetes-admin@$(CLUSTER)
CERTMGR_VERSION ?= 299f546b4d8a61af19e94545ed4fc1c35dee35e0
HELM_VERSION   ?= 2.11.0
SEKRET_VERSION ?= 1.2.1
STACKS  = $(basename $(wildcard *.yaml))

include Makefile.vars

ifeq ($(ACTION), delete)
  NOTICE=Removing
else
  NOTICE=Deploying
endif

all: imports $(INSTALL_YAML) $(STACKS)

mariadb-galera::
	@echo Please specify a specific instance e.g. db03 && exit 1

db00 db01 db02 db03:
	@echo --$(NOTICE) $@--
	@SERVICE_NAME=$@ DB_IP=$(shell dig +short $@.$(DOMAIN)) \
	  envsubst < mariadb-galera.yaml | kubectl $(ACTION) -f -

gitlab-runner::
	@echo Use gitlab-agent target

gitlab-agent:
	@echo Installing service with privileged /var/run/docker.sock access
	@SERVICE_NAME=gitlab-runner \
	  envsubst < gitlab-runner.yaml | kubectl $(ACTION) $(ADMIN_CTX) -n gitlab -f -
	-sekret dec secrets/$(CA_SECRET) | envsubst | kubectl create $(ADMIN_CTX) -n gitlab -f -

wordpress::
	@echo Please specify a specific instance e.g. wordpress-ci && exit 1

wordpress-ci wordpress-il:
	@echo --$(NOTICE) $@--
	$(eval fqdn := $(shell case $@ in (wordpress-ci) echo www.ci.net;;\
	  (wordpress-il) echo www.instantlinux.net;; esac))
	@SERVICE_NAME=$@ DB_NAME=$(shell echo $@ | tr - _) HOST_FQDN=$(fqdn) \
	  envsubst < wordpress.yaml | kubectl $(ACTION) -f -

$(STACKS)::
	@echo --$(NOTICE) $@--
	@SERVICE_NAME=$(@F) \
	  envsubst < $@.yaml | kubectl $(ACTION) --namespace $(K8S_NAMESPACE) -f -

##########
# Installation
##########
.PHONY: helm_install imports install node_labels persistent secrets \
	untaint_master

IMPORTS      = dashboard flannel ingress-nginx
INSTALL_YAML = $(basename $(wildcard install/*.yaml)) \
          $(addprefix imports/, $(IMPORTS))
VOLUMES_YAML = $(basename $(wildcard volumes/*.yaml))

install: install/admin-user install/namespace install/limits \
	install/namespace-user install/namespace-cert-manager \
	install/podsecurity storage_localdefault imports install_imports \
	install/k8s-backup install/local-storage \
	install/logspout install/gitlab-rbac extend_dashboard_ttl helm_install \
	sekret secrets data-sync-ssh volumes/nfs ~/.kube/config.conf persistent

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

storage_localdefault:
	kubectl $(ADMIN_CTX) patch storageclass local-storage -p \
	  '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

##########
# Helm
##########
.PHONY: helm_install tiller_install tiller_protect tiller_disable tiller_enable
helm_install: /usr/local/bin/helm tiller_install tiller_protect \
	~/.helm/repository/cache/bitnami-index.yaml

tiller_install:
	helm init --kube-context=kubernetes-admin@$(CLUSTER)

# plug ghastly security hole, https://github.com/anguslees/helm-security-post
tiller_protect:
	-kubectl $(ADMIN_CTX) create serviceaccount --namespace kube-system tiller
	-kubectl $(ADMIN_CTX) create clusterrolebinding tiller-cluster-rule \
	  --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
	kubectl $(ADMIN_CTX) patch deploy --namespace kube-system tiller-deploy \
	  -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
	-kubectl $(ADMIN_CTX) delete service tiller-deploy --namespace kube-system
	kubectl $(ADMIN_CTX) patch deployment tiller-deploy --namespace kube-system \
	  --patch='$(shell cat install/tiller-patch.json)'

# Only run tiller when needed (until its security is tighter, someday)
tiller_disable: imports/tiller_deploy.yaml
	kubectl $(ADMIN_CTX) delete deployment.apps/tiller-deploy --namespace kube-system

tiller_enable:
	kubectl $(ADMIN_CTX) $(ACTION) -f imports/tiller_deploy.yaml

imports/tiller_deploy.yaml:
	kubectl $(ADMIN_CTX) get deployment.apps/tiller-deploy --namespace kube-system \
	  -o yaml > $@

/usr/local/bin/helm:
	wget -O /tmp/helm-amd64.tar.gz \
	  https://storage.googleapis.com/kubernetes-helm/helm-v$(HELM_VERSION)-linux-amd64.tar.gz
	wget -O /tmp/helm-amd64.sha256 \
	  https://storage.googleapis.com/kubernetes-helm/helm-v$(HELM_VERSION)-linux-amd64.tar.gz.sha256
	echo "$(shell cat /tmp/helm-amd64.sha256)  /tmp/helm-amd64.tar.gz" | sha256sum -c
	tar xf /tmp/helm-amd64.tar.gz -C /tmp
	sudo mv /tmp/linux-amd64/helm /tmp/linux-amd64/tiller /usr/local/bin
	rm -r /tmp/helm-amd64.* /tmp/linux-amd64

~/.helm/repository/cache/bitnami-index.yaml:
	helm repo add bitnami https://charts.bitnami.com/bitnami

##########
# Secrets
##########
sekret: /usr/local/bin/sekret
/usr/local/bin/sekret:
	curl -sLo /tmp/sekret_linux_amd64 \
	  https://github.com/nownabe/sekret/releases/download/v$(SEKRET_VERSION)/sekret_linux_amd64
	curl -sLo /tmp/sekret.sha256 \
	  https://github.com/nownabe/sekret/releases/download/v$(SEKRET_VERSION)/sekret_$(SEKRET_VERSION)_checksums.txt
	cd /tmp && grep linux_amd64 sekret.sha256 | sha256sum -c
	sudo mv /tmp/sekret $@
	sudo chmod 755 $@
	rm /tmp/sekret*

SECRETS = secrets/*
secrets: secrets/*
secrets/*::
	-sekret dec $@ | envsubst | kubectl create -f -

##########
# cert-manager
##########

# NOT working; TODO resume work on this when setup doc and non-helm install are fixed
#  See: https://github.com/jetstack/cert-manager/issues/1151
cert-manager: imports/00-crds.yaml imports/cert-manager.yaml
	kubectl	$(ADMIN_CTX) $(ACTION) -f imports/00-crds.yaml
	kubectl	$(ADMIN_CTX) $(ACTION) -f imports/cert-manager.yaml

imports/00-crds.yaml imports/cert-manager.yaml:
	curl -sLo $@ https://raw.githubusercontent.com/jetstack/cert-manager/$(CERTMGR_VERSION)/deploy/manifests/$(@F)

##########
# Add-ons
##########
imports: $(foreach file,$(IMPORTS),imports/$(file).yaml)
install_imports: $(foreach file, $(IMPORTS), imports/$(file))

# extend annoying default 15-minute timeout
.PHONY: extend_dashboard_ttl
extend_dashboard_ttl:
	kubectl $(ADMIN_CTX) patch deployment kubernetes-dashboard --namespace kube-system \
	  --patch='$(shell cat install/dashboard-patch.json)'

imports/dashboard.yaml:
	mkdir -p imports
	curl -sLo $@ https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml

imports/flannel.yaml:
	curl -sLo $@ https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
	sed -i -e 's/"Type": "vxlan"/"Type": "host-gw"/' $@

imports/ingress-nginx.yaml:
	curl -sLo $@ https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/mandatory.yaml

imports/traefik-prom.yaml:
	curl -sLo $@ https://raw.githubusercontent.com/mateobur/prometheus-monitoring-guide/master/traefik-prom.yaml

# Not used, TODO consider calico network
imports/weave-net.yaml:
	curl -sLo $@ https://cloud.weave.works/k8s/net?k8s-version=$(shell kubectl version | base64 | tr -d '\n')

etcd:
	helm install --name etcd --namespace $(K8S_NAMESPACE) \
	  --kube-context=kubernetes-admin@$(CLUSTER) \
	  bitnami/etcd --set auth.rbac.enabled=false
	sleep 30
	kubectl scale statefulset etcd-etcd --namespace=$(K8S_NAMESPACE) --replicas=3
