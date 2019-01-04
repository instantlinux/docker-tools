## k8s

Kubernetes is a circa-2014 successor to Google's circa-2003 Borg
project. Docker Inc. created a rival technology, Docker Swarm, which
dominated my efforts in this repo until I finally concluded that by
mid-2017 the vastly harder-to-use / harder-to-learn Kubernetes
technology had eliminated Swarm from meaningful contention in the
enterprise market.

This repo is an attempt to make Kubernetes more approachable for any
user who wants to get started easily, with a real cluster (not just
a single-instance minikube setup) on bare-metal. Most of this will
probably work in IaaS providers like Google or AWS but the purpose
of this repo is to set up production-grade K8S with your own servers / VMs.

### Features

The ansible playbook deploys master and node instances with kubeadm,
with full-disk LUKS encryption for local volumes. The Makefile in
this directory adds these capabilities which aren't part of the
kubeadm suite:

* Pod security policies
* Direct-attached SSD local storage pools
* Dashboard
* Non-default namespace with its own service account (full permissions
  within namespace, limited read-only in kube-system namespaces)
* Helm with tiller
* Sekret with encryption (to keep credentials in local git repo)
* Encryption for internal etcd
* Flannel networking
* ingress-nginx
* Letsencrypt certs (TODO)

Resource yaml files are in standard k8s format, parameterized by simple
environment-variable substitution. Helm is provided only to enable
access to published helm charts; resources herein are defined using the
Kubernetes-native API syntax.

### Requirements and cost

Set up three or more bare-metal quad-core servers or VMs with at least
a couple gigabytes of RAM each. At present [kubeadm is limited](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/#limitations) to a single
master node so the recommended configuration to support clustered
services such as etc and MariaDB is 4+ nodes. (An inexpensive node
similar to mine is an [Intel J5005 NUC](https://www.newegg.com/Product/Product.aspx?Item=N82E16856102204) with two 8GB DDR4 RAM modules
and a 500GB to 2TB drive installed in each. Yes, you *can* put 16GB of
RAM into a Goldmont / Gemini Lake mainboard, just flat-out ignore
Intel's inexplicable 8GB-max claims. As of Nov 2018 a J5005 with 16GB
of RAM and 500GB of SSD costs just under $400USD so three of those
plus a master node of 250GB SSD and 8GB of RAM totals $1500USD; you
can shave maybe $400 off by reducing RAM and storage, and another $300
by virtualizing the manager on your existing server.

### Assumptions

* You're not running in a cloud provider (this probably works in
  cloud instances but isn't tested there; if you're already in
  cloud and willing to pay for it you don't need this tool anyway)
* You want to run a current stable version of docker engine
* You're running Ubuntu 18.04 LTS on the nodes
* You want fastest / most secure direct-attached SSD performance:
  persistent storage will be local LUKS-encrypted directories on
  each node
* You have a local docker registry, or plan to use a public one
  such as hub.docker.com
* You want the simplest way to manage kubernetes, with tools like
  _make_ rather than helm / ksonnet / ansible (I independently opted
  to learn kubernetes this way, as described in [Using Makefiles and
  envsubst as an Alternative to Helm and Ksonnet](https://vadosware.io/post/using-makefiles-and-envsubst-as-an-alternative-to-helm-and-ksonnet/) by vados.

### Repo layout

| File | Description |
| --------- | ----------- |
| install/ | supporting resources |
| ../ansible/k8s-node | ansible-playbook node installer |
| scripts/ | supporting scripts |
| secrets/ | symlink to private directory of encrypted secrets |
| volumes/ | (deprecated) persistent volume claims |
| Makefile | resource deployer |
| *.yaml | applications as noted in top-level README |

### How to use this

First create an ansible host inventory with your nodes defined, for
example:
```
[k8s_master]
master.domain.com

[k8s_nodes]
kube1.domain.com
kube2.domain.com
kube3.domain.com
```

Choose a namespace and a 32-byte encryption key, and define these
environment variables with values as desired:
```
export DOMAIN=domain.com
export EDITOR=vi
export ENCRYPTION_KEY=3zQ#LgGGc9R&9z5@Z^68H6Gz6Q7vQ1z2
export K8S_NAMESPACE=mynamespace
export K8S_NODES="kube1.$DOMAIN kube2.$DOMAIN"
export TZ=America/Los_Angeles
```

Customize the Makefile.vars files with any additional settings you
desire.

Create group_vars/k8s_master.yml and group_vars/k8s_node files
that contains definitions like this:

```
luks_vg: vg01

luks_volumes:
  volkube:
    inodes: 10000
    path: /var/lib/docker/k8s-volumes
    size: 100000
    vg: "{{ luks_vg }}"
```

The ansible playbook k8s-master install dockers and configures
master. The playbook can generate LUKS-encrypted volume mounts for
your data as above; the ansible playbook includes a role that can
reference a remote volume (I use sshfs for this) that holds the keys
under a /masterlock directory. Build the master thus:

```
ansible-playbook k8s-master.yml
```
Kubernetes should be up and running at this point, with a bare-minimum
configuration.

Set up a local repo to define environment variables. Kubernetes resources
here are defined in the native YAML format but with one extension: they
are parameterized by the use of _envsubst_ which allows values to be
passed in as shell environment variables in the form $VARIABLE_NAME.

Set a symlink from a directory under this one (k8s/secrets) to a
subdirectory in your local administrative repo. This is where you will
store kubernetes secrets, encrypted by a tool called _sekret_.

Then invoke the following in this directory:
```
make install
```
This will add flannel networking, the dashboard, an nginx ingress
load-balancer, helm and sekret. Create directories for persistent
volumes for each node, and optionally set node-affinity labels:
```
for node in $K8S_NODES; do
  NODE=$node make persistent_dirs
done
make node_labels
```

This Makefile generates a sudo context and a default context with
fewer permissions in your ~/.kube directory.

Verify you can reach the dashboard after running _kubectl proxy_ at
http://localhost:8001. Verify that you can view the core services
like this:
```
$ kubectl get nodes
NAME               STATUS   ROLES    AGE   VERSION
master.domain.com  Ready    master   27m   v1.13.0
kube1.domain.com   Ready    <none>   16m   v1.13.0
kube2.domain.com   Ready    <none>   16m   v1.13.0
$ kubectl get pods --context=sudo
NAME                                    READY   STATUS    RESTARTS   AGE
coredns-86c58d9df4-7fzf7                1/1     Running   0          16m
coredns-86c58d9df4-qs8rc                1/1     Running   0          16m
etcd-master.domain.com                  1/1     Running   0          26m
kube-apiserver-master.domain.com        1/1     Running   0          26m
kube-controller-manager-master.domain.com 1/1   Running   0          25m
kube-flannel-ds-amd64-24h7l             1/1     Running   0          16m
kube-flannel-ds-amd64-94fpx             1/1     Running   1          26m
kube-flannel-ds-amd64-hkmv2             1/1     Running   0          16m
kube-proxy-2lp59                        1/1     Running   0          16m
kube-proxy-bxtsm                        1/1     Running   0          16m
kube-proxy-wk6qw                        1/1     Running   0          26m
kube-scheduler-master.domain.com        1/1     Running   0          25m
kubernetes-dashboard-769df7fb6d-qdzjm   1/1     Running   0          26m
logspout-nq95g                          1/1     Running   0          26m
logspout-tbz65                          1/1     Running   0          16m
logspout-whmhb                          1/1     Running   0          16m
tiller-deploy-6b6d4b6895-d8mxt          1/1     Running   0          26m
```

Check /var/log/syslog, and the output logs of pods that you can access
via the Kubernetes console, to troubleshoot problems.

### Status

This section of the repo is very much alpha, it's intended to help get
started with kubectl, helm, letsencrypt and sekret but there will
still be a learning curve to get the volume mounts set up, permissions
set and application configurations fully working.
