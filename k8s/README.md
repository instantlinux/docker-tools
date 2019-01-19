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
* Mozilla [sops](https://github.com/mozilla/sops/blob/master/README.rst) with encryption (to keep credentials in local git repo)
* Encryption for internal etcd
* Flannel networking
* ingress-nginx
* Local-volume sync
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

Choose a namespace and a random (~32 bytes) encryption key, and define these
environment variables with values as desired:
```
export DOMAIN=domain.com
export EDITOR=vi
export K8S_NAMESPACE=mynamespace
export K8S_NODES="kube1.$DOMAIN kube2.$DOMAIN"
export TZ=America/Los_Angeles
```

Customize the Makefile.vars files with any additional settings you
desire.

Put the encryption key into an ansible vault variable
_vault_k8s.encryption_key_ under group_vars/all/vault.yml. Create
group_vars/k8s_master.yml and group_vars/k8s_node files that contains
definitions like this:

```
luks_vg: vg01

luks_volumes:
  volkube:
    inodes: 10000
    path: /var/lib/docker/k8s-volumes
    size: 100000
    vg: "{{ luks_vg }}"
```

The ansible directory includes a role that can reference a remote
volume (using sshfs) that holds the keys under a /masterlock
directory. To set up the LUKS disk encryption provided by this role:

* make a volume /masterlock on a secure server, owned by username _masterlock_
* generate random keyfiles for each node's volumes under /masterlock/keys/<node>/<volume>.
* generate a ssh keypair for the masterlock user
* put the private key into an ansible-vault variable vault_ssh_keys_private.masterkey (convert newline characters into \n)
* put the public key into ~masterlock/.ssh/authorized_keys on the secure server
* the secure server is only needed by each node at reboot time (so it can be defined "serverless" with a launch trigger at reboot, but that's outside scope of this doc)
* next step will then generate correct fstab entries for each node

The ansible playbook k8s-master installs docker and configures
master. The playbook will generate LUKS-encrypted volume mounts for
your data as above; build the master thus:

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
store kubernetes secrets, encrypted by a tool called _sops_.

Then invoke the following in this directory:
```
make install
```
This will add flannel networking, the dashboard, an nginx ingress
load-balancer, helm and sops. Create directories for persistent
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

Credentials can be kept in a local git repo; invoke
_make sops sops_gen_gpg_ to install sops and create your private
key. Once you've done that, add new secrets by invoking
_make secrets/keyname.yml_.  Upload them to Kubernetes by invoking
_make secrets/keyname_. Manage their contents and lifecycle using the
_sops_ command. This tool also supports cloud key-managers like KMS,
but gpg is suitable for bare-metal data center setups.

### Network and local storage

Storage management is a mostly-unsolved problem in the container world; indeed there are startup companies raising cash to try to solve this in ways that will be affordable only to big enterprises (a blogger at StorageOS has [this to say](https://medium.com/@saliloquy/storage-is-the-achilles-heel-of-containers-97d0341e8d87)). Long before Swarm and Kubernetes came out, I was using LVM snapshots to quickly clone LXC containers, and grew accustomed to the speedy performance of direct-attached SSD storage. At a former employer, in order to provide resiliency for database masters, I used [drbd](http://www.drbd.org) to sync volumes at the block level across the network.

The solutions I present here in this repo are based on those years of experience, and rely only on free open-source tools. Kubernetes does not support Docker's local named volumes, so I had to develop a new paradigm when switching from Swarm to Kubernetes.

* To generate k8s _pv_ objects for each local nodes' volumes (pools and named volumes), invoke _make persistent_ which triggers a script [persistent.sh](https://github.com/instantlinux/docker-tools/tree/master/k8s/scripts).
* To create the named LUKS-encrypted volumes, mount points and local directories, configure variables for the Ansible role [volumes](https://github.com/instantlinux/docker-tools/tree/master/ansible/roles/volumes) and invoke the playbook [k8s-node.yml](https://github.com/instantlinux/docker-tools/blob/master/ansible/k8s-node.yml).
* My customized NFS mount points, which are provided to k8s through _pvc_ objects, are defined in [k8s/volumes](https://github.com/instantlinux/docker-tools/tree/master/k8s/volumes).
* At present, k8s only supports NFS v3 protocol--which means it's a single point of failure--and it doesn't yet support CIFS. It's unfortunate that I need to use NFS at all; if you can avoid it, do so wherever possible--the kubelet will go unstable if the NFS server's mount points ever go away.
* To provide resiliency, I created a [data-sync](https://cloud.docker.com/repository/docker/instantlinux/data-sync) container and [kubernetes.yaml](https://github.com/instantlinux/docker-tools/blob/master/images/data-sync/kubernetes.yaml) deployment to keep multiple copies of a local storage volume in sync. These volumes currently have to be mounted using hostPath (not 100% secure) by the application containers.
* The k8s _statefulset_ resource can attach local named volumes or assign them from a pool; it's designed for clustered applications that can run multiple instances in parallel, each with its own data storage
* The k8s _deployment_ resource can attach to a hostPath or NFS mount point; this resource type is preferred for non-clustered applications that run as a single instance within your k8s cluster

I've tried several different approaches to keeping volumes in sync; the most popular alternative is GlusterFS but my own experience with that included poor performance on volumes with more than about 10,000 files, difficult recovery in split-brain network failures, and sporadic undetected loss of sync. All those tools (drbd included) are hugely complex to understand/administer. The [unison](https://www.cis.upenn.edu/~bcpierce/unison/) tool is as easy to understand as _rsync_ and has never had any failures in my years of use. The main catch with unison is that you need to identify and exclude files that are constantly being written to by your application, and/or create a script to quiesce the application during sync operations.

Explore this repo for several different approaches to data backups. Duplicati is the main off-the-shelf tool that I've found as an alternative to CrashPlan for Home, though it's got one major achille's heel (metadata indexing) it's better than any other no-cost Linux tool. My [secondshot](https://github.com/instantlinux/secondshot)_ tool adds metadata-indexing and monitoring to the _rsnapshot_ method.

### Additional notes

I've run into a ton of issues, minor and major, setting up Kubernetes on
bare-metal. Where practical, I've implemented solutions-as-code to every
issue but some things aren't quite as readily automated or will likely
be addressed in future versions of the rapidly-evolving codebase. These
notes are as of Jan 2019 on version 1.13.1:

* VirtualBox, the de facto way of setting up test environments under Linux,
  doesn't play nicely at all with Kubernetes networking. If you run
  coredns under VirtualBox, you simply don't get DNS resolution outside
  the node it's running on--the UDP packets disappear more often than not.
  Run coredns on bare-metal or some other virtualiizion or cloud method.
  There are hints of how to address this in [issue #70851](https://github.com/kubernetes/kubernetes/issues/70851).

* The eviction manager's default settings lead to an unstable installation
  unless you have a way of ensuring ample image-store space on each node.
  For whatever reason, Kubernetes' maintainers decided it was a good idea
  to (repeatedly) shut down running pods in a vain attempt to free up
  image-store when this resource is low, even though there's little or
  no log-file output to indicate what the problem might be. And there
  are bugs, such as [issue #60558](https://github.com/kubernetes/kubernetes/issues/60558).
  My specific advice: disable this entirely by changing the setting of
  evictionHard:imagefs.available from 15% to 0% in /var/lib/kubelet/config.yaml.
  There's a [Dynamic Kubelet Config](https://github.com/kubernetes/enhancements/issues/281)
  project to automate updating this file so I haven't added such
  automation here. That way you can use your own favorite tools for alerting
  on or handling low volume storage (I use the thinpool autoextend method,
  which is part of the ansible docker role here).

* Static IP addresses to set up in your routing infrastructure, and
  ways to set up HA load-balancing, for bare-metal installations are
  glaringly less-than-obvious in the docs. I've gotten a
  just-barely-working setup going myself; it's far less straightforward
  to get true HA networking with kubernetes than it was with Swarm.

* I haven't yet sorted out how to separate database write traffic from
  database reads, and how to send the write traffic to a specified node
  from any given application (splitting database writes across a MariaDB
  cluster isn't fully supported at this time, there are race conditions
  which create performance problems).

* I haven't yet addressed cert-manager/letsencrypt here. It looked to me
  like that project is in rapid evolution so I tabled the idea until a
  future date when their doc is more polished.
