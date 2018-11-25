#
# Usage - set up in this sequence:
#   make install
#     ^^ then copy/paste token: <value> after last line of .kube/config
#   NODE=(node).domain make persistent_dirs
#   make persistent
#   NODE=(master).domain make untaint_master
#
# Then:
#   make <service>
#   ACTION=delete make <service>

ACTION         ?= apply
HELM_VERSION   ?= 2.11.0
SEKRET_VERSION ?= 1.2.1
IMPORTS         = dashboard flannel ingress-nginx
STACKS  = $(basename $(wildcard *.yaml install/*.yaml)) \
          $(addprefix imports/, $(IMPORTS))
export NODES          ?= $(K8S_NODES)
export VOL_NUM_SMALL   = 0030
export VOL_NUM_MEDIUM  = 0010
export VOL_SIZE_SMALL  = 500Mi
export VOL_SIZE_MEDIUM = 8Gi

export K8S_INGRESS_NGINX_IP ?= 10.101.1.1

ifeq ($(ACTION), delete)
  NOTICE=Removing
else
  NOTICE=Deploying
endif

all: imports $(STACKS)

$(STACKS)::
	@echo --$(NOTICE) $@--
	@SERVICE_NAME=$(@F) \
	  envsubst < $@.yaml | kubectl $(ACTION) -f -

db03:
	@echo --$(NOTICE) $@--
	@CLUSTER_NAME=$@ \
	 SERVICE_NAME=$@ \
	  envsubst < mariadb-galera.yaml | kubectl $(ACTION) -f -

##########
# Installation
##########
install: install/admin-user install/namespace imports install_imports \
	install/ingress-nginx-nodeport helm_install secrets sekret show_token

show_token:
	kubectl -n kube-system describe secret $(shell kubectl -n kube-system \
	  get secret | grep admin-user | awk '{print $$1}')
	@echo
	@echo "** Add above token to .kube/config, and protect against\
	 prying eyes **"

untaint_master:
	# Allow workload on master (not recommended)
	kubectl taint nodes $(NODE) node-role.kubernetes.io/master-

##########
# Storage
##########
persistent:
	./scripts/persistent.sh $(NODES)

persistent_dirs::
	ssh $(NODE) sudo 'mkdir -p $$(echo \
	  /var/lib/docker/k8s-volumes/pv-$(VOL_SIZE_SMALL)-{0001..$(VOL_NUM_SMALL)} \
	  /var/lib/docker/k8s-volumes/pv-$(VOL_SIZE_MEDIUM)-{0001..$(VOL_NUM_MEDIUM)})'

storage_localdefault:
	kubectl patch storageclass local-storage -p \
	  '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

##########
# Helm
##########
helm_install:: /usr/local/bin/helm tiller_protect \
	~/.helm/repository/cache/bitnami-index.yaml

# plug ghastly security hole, https://github.com/anguslees/helm-security-post
tiller_protect:
	-kubectl create serviceaccount --namespace kube-system tiller
	-kubectl create clusterrolebinding tiller-cluster-rule \
	  --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
	kubectl patch deploy --namespace kube-system tiller-deploy \
	  -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
	-kubectl delete service tiller-deploy --namespace kube-system
	kubectl patch deployment tiller-deploy --namespace kube-system \
	  --patch='$(shell cat install/tiller-patch.json)'

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
	sekret dec $@ | envsubst | kubectl apply -f -

##########
# Add-ons
##########
imports: $(foreach file,$(IMPORTS),imports/$(file).yaml)
install_imports: $(foreach file, $(IMPORTS), imports/$(file))

# extend annoying default 15-minute timeout
extend_dashboard_ttl:
	kubectl patch deployment kubernetes-dashboard --namespace kube-system \
	  --patch='$(shell cat install/dashboard-patch.json)'

imports/dashboard.yaml:
	mkdir -p imports
	curl -sLo $@ https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml

imports/flannel.yaml:
	curl -sLo $@ https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

imports/ingress-nginx.yaml:
	curl -sLo $@ https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/mandatory.yaml

etcd:
	helm install --name etcd --namespace $(K8S_NAMESPACE) bitnami/etcd
	kubectl scale statefulset etcd-etcd --namespace=$(K8S_NAMESPACE) --replicas=3
