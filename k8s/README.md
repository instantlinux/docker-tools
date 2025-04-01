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

See [How to use this](#how-to-use-this) below to get started.

### Features

The ansible playbook deploys control-plane and worker instances with
kubeadm, with full-disk LUKS encryption for local volumes. The Makefile
in this directory adds these capabilities which aren't part of the
kubeadm suite:

* Direct-attached SSD local storage pools
* Non-default namespace with its own service account (full permissions
  within namespace, limited read-only in kube-system namespaces)
* Helm
* Keycloak for login auth to kube-apiserver
* A k8sudo script to encrypt/decrypt k8s admin key
* Mozilla [sops](https://github.com/mozilla/sops/blob/master/README.rst) with encryption (to keep credentials in local git repo)
* Encryption for internal etcd
* MFA using [Authelia](https://github.com/clems4ever/authelia) and Google Authenticator
* Calico or flannel networking
* ingress-nginx
* Local-volume sync
* Automatic certificate issuing/renewal with Letsencrypt

Resource yaml files are in standard k8s format, parameterized by simple
environment-variable substitution. Helm is provided only to enable
access to published helm charts; resources herein are defined using the
Kubernetes-native API syntax.

### Requirements and cost

Set up three or more bare-metal quad-core servers or VMs with at least
a couple gigabytes of RAM each. At present [kubeadm is limited](https://kubernetes.io/docs/setup/independent/create-cluster-kubeadm/#limitations) to a single
control-plane node so the recommended configuration to support clustered
services such as etc and MariaDB is 4+ nodes. (An inexpensive node
similar to mine is an [Intel N6005 Mini PC](https://www.newegg.com/neosmay-ac8-jasper-lake/p/2SW-006Y-00003) with two 8GB DDR4 RAM modules
and a 500GB to 2TB drive installed in each.) As of Sep 2022 three of these configured with 16GB of RAM and 512GB SSD costs plus a control-plane node of 250GB SSD and 8GB of RAM add up to about $1250USD; you
can shave maybe $400 off by reducing RAM and storage, and another $250
by virtualizing the manager on your existing server. By Nov 2024, costs of such nodes has plunged: Intel N100 quad-core mini-PCs with 16GB of RAM and 512GB SSD can be had for under $150, so four of these is under $600.

### Assumptions

* You're not running in a cloud provider (this probably works in
  cloud instances but isn't tested there; if you're already in
  cloud and willing to pay for it you don't need this tool anyway)
* You want to run a current stable version of docker engine
* You're running Ubuntu 24.04 LTS on the nodes
* You want fastest / most secure direct-attached SSD performance:
  persistent storage will be local LUKS-encrypted directories on
  each node
* You have a local docker registry, or plan to use a public one
  such as hub.docker.com
* You want the simplest way to manage kubernetes, with tools like
  _make_ and _helm_ rather than ksonnet / ansible (I independently opted
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
[k8s_cplane]
cp.domain.com

[k8s_nodes]
kube1.domain.com
kube2.domain.com
kube3.domain.com
```

Choose a namespace and define these environment variables with values
as desired:
```
export DOMAIN=domain.com
export EDITOR=vi
export K8S_NAMESPACE=mynamespace
export K8S_NODES="kube1.$DOMAIN kube2.$DOMAIN"
export TZ=America/Los_Angeles
```

Customize the [Makefile.vars](https://github.com/instantlinux/docker-tools/blob/main/k8s/Makefile.vars) file with any additional settings you
desire. (You can override settings in that file without editing,
if you prefer, with environment variables in a bash .profile.)

Choose a random (~32 bytes) encryption key and put it into an ansible
vault variable _vault_k8s.encryption_key_ under
group_vars/all/vault.yml. Create group_vars/k8s_cplane.yml and
group_vars/k8s_node files that contains definitions like this:

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

The ansible playbook k8s-cplane installs docker and configures
the control plane. The playbook will generate LUKS-encrypted volume mounts for
your data as above; build it thus:

```
ansible-playbook k8s-cplane.yml
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

### OpenID

To tighten security by creating API users you will need to set up OpenID / OAuth2. An on-site user directory can be established using the open-source tool [Keycloak](https://www.keycloak.org/) (a docker-compose file is provided under [services/keycloak](https://github.com/instantlinux/docker-tools/tree/main/services/keycloak/docker-compose.yml)) for which a somewhat complicated configuration is required (TODO - I'll write up the procedure in the docs here). Start by downloading [krew](https://github.com/kubernetes-sigs/krew/releases/latest/download/krew-linux_amd64.tar.gz) and adding it to your $PATH. To get a single-user setup working, follow these steps:

* Go to your google account and add client-id k8slogin of type desktop, in [credentials dashboard](https://console.cloud.google.com/apis/credentials);
* Run these commands, filling in the redacted fields from first step:
```
CLIENT_ID=<redacted>
CLIENT_SECRET=<redacted>
kubectl krew install oidc-login
kubectl oidc-login setup  --oidc-issuer-url=https://accounts.google.com \
  --oidc-client-id=$CLIENT_ID --oidc-client-secret=$CLIENT_SECRET
# copy-paste following command from setup output item 3
kubectl create clusterrolebinding oidc-cluster-admin \
  --clusterrole=cluster-admin \
  --user='https://accounts.google.com#<redacted>
```
* Add a user to ~/.kube/config:
```
- name: oidc-google
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1beta1
      command: kubectl
      args:
      - oidc-login
      - get-token
      - --oidc-issuer-url=https://accounts.google.com
      - --oidc-client-id=<redacted>
      - --oidc-client-secret=<redacted>
- context:
    cluster: kubernetes
    namespace: mynamespace
    user: oidc
  name: user@kubernetes
```
Alternatively, you can set up Keycloak on a local container, which provides finer-granularity group permissions. Setting that up is beyond scope of this README (and a warning, Keycloak's documentation is not easy to follow). Once the user and group is set up, verify with:
```
PW=<redacted>
export TOKEN=$(curl -d username=$USER -d "password=$PW" \
  -d grant_type=password \
  -d client_id=k8s-access \
  -d client_secret=$CLIENT_SECRET \
  https://oidc.instantlinux.net/realms/k8s/protocol/openid-connect/token | \
  jq -r '.access_token')
echo $TOKEN
curl -X GET https://oidc.instantlinux.net/realms/k8s/protocol/openid-connect/userinfo \
  -H "Accept: application/json" \
  -H "Authorization: Bearer $TOKEN" | jq .
```
and the response will look similar to this:
```
{
  "sub": "bdeec4c0-5070-4c6a-ac25-1fb0f26ccc1b",
  "email_verified": true,
  "name": "Rich Braun",
  "groups": [
    "/instantlinux"
  ],
  "preferred_username": "richb",
  "given_name": "Rich",
  "family_name": "Braun",
  "email": "richb@pioneer.ci.net",
  "username": "richb"
}
```
Look in the k8s/install subdirectory for resources in namespace-user.yaml for examples of how to map oidc username from Keycloak to k8s Role and ClusterRole permissions.

### Installation

To configure k8s resources, invoke the following in this directory ([k8s](https://github.com/instantlinux/docker-tools/tree/main/k8s)):
```
make install
```
This will add flannel networking, an nginx ingress load-balancer,
helm and sops. Create directories for persistent volumes for each node,
and optionally set node-affinity labels:
```
for node in $K8S_NODES; do
  NODE=$node make persistent_dirs
done
make node_labels
```

This Makefile generates a sudo context and a default context with
fewer permissions in your ~/.kube directory.

Verify that you can view the core services like this:
```
$ kubectl get nodes
NAME               STATUS   ROLES          AGE   VERSION
cp.domain.com      Ready    control-plane  27m   v1.31.2
kube1.domain.com   Ready    <none>         16m   v1.31.2
kube2.domain.com   Ready    <none>         16m   v1.31.2
$ kubectl get pods -n kube-system --context=sudo
NAME                                    READY   STATUS    RESTARTS   AGE
coredns-86c58d9df4-7fzf7                1/1     Running   0          16m
coredns-86c58d9df4-qs8rc                1/1     Running   0          16m
etcd-cp.domain.com                      1/1     Running   0          26m
kube-apiserver-cp.domain.com            1/1     Running   0          26m
kube-controller-manager-cp.domain.com   1/1     Running   0          25m
kube-flannel-ds-amd64-24h7l             1/1     Running   0          16m
kube-flannel-ds-amd64-94fpx             1/1     Running   1          26m
kube-flannel-ds-amd64-hkmv2             1/1     Running   0          16m
kube-proxy-2lp59                        1/1     Running   0          16m
kube-proxy-bxtsm                        1/1     Running   0          16m
kube-proxy-wk6qw                        1/1     Running   0          26m
kube-scheduler-cp.domain.com            1/1     Running   0          25m
logspout-nq95g                          1/1     Running   0          26m
logspout-tbz65                          1/1     Running   0          16m
logspout-whmhb                          1/1     Running   0          16m
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

### Certificate Manager

Cert-manager installation is part of the above _make install_; to
start the issuer invoke:
```
CERT_MGR_EMAIL=<my email> make install/cert-manager
```
A lot of things have to be functioning before letsencrypt will issue certs: the [Let's Encrypt troubleshooting guide](https://cert-manager.io/docs/troubleshooting/acme/) is super-helpful.

### Network and local storage

Storage management is a mostly-unsolved problem in the container world; indeed there are startup companies raising cash to try to solve this in ways that will be affordable only to big enterprises (a blogger at StorageOS has [this to say](https://medium.com/@saliloquy/storage-is-the-achilles-heel-of-containers-97d0341e8d87)). Long before Swarm and Kubernetes came out, I was using LVM snapshots to quickly clone LXC containers, and grew accustomed to the speedy performance of direct-attached SSD storage. At a former employer, in order to provide resiliency for database masters, I used [drbd](http://www.drbd.org) to sync volumes at the block level across the network.

The solutions I present here in this repo are based on those years of experience, and rely only on free open-source tools. Kubernetes does not support Docker's local named volumes, so I had to develop a new paradigm when switching from Swarm to Kubernetes.

* To generate k8s _pv_ objects for each local nodes' volumes (pools and named volumes), invoke _make persistent_ which triggers a script [persistent.sh](https://github.com/instantlinux/docker-tools/tree/main/k8s/scripts).
* To create the named LUKS-encrypted volumes, mount points and local directories, configure variables for the Ansible role [volumes](https://github.com/instantlinux/docker-tools/tree/main/ansible/roles/volumes) and invoke the playbook [k8s-node.yml](https://github.com/instantlinux/docker-tools/blob/main/ansible/k8s-node.yml).
* My customized NFS mount points, which are provided to k8s through _pvc_ objects, are defined in [k8s/volumes](https://github.com/instantlinux/docker-tools/tree/main/k8s/volumes).
* At present, k8s only supports NFS v3 protocol--which means it's a single point of failure--and it doesn't yet support CIFS. It's unfortunate that I need to use NFS at all; if you can avoid it, do so wherever possible--the kubelet will go unstable if the NFS server's mount points ever go away.
* To provide resiliency, I created a [data-sync](https://cloud.docker.com/repository/docker/instantlinux/data-sync) container and [kubernetes.yaml](https://github.com/instantlinux/docker-tools/blob/main/images/data-sync/kubernetes.yaml) deployment to keep multiple copies of a local storage volume in sync. These volumes currently have to be mounted using hostPath (not 100% secure) by the application containers.
* The k8s _statefulset_ resource can attach local named volumes or assign them from a pool; it's designed for clustered applications that can run multiple instances in parallel, each with its own data storage
* The k8s _deployment_ resource can attach to a hostPath or NFS mount point; this resource type is preferred for non-clustered applications that run as a single instance within your k8s cluster

I've tried several different approaches to keeping volumes in sync; the most popular alternative is GlusterFS but my own experience with that included poor performance on volumes with more than about 10,000 files, difficult recovery in split-brain network failures, and sporadic undetected loss of sync. All those tools (drbd included) are hugely complex to understand/administer. The [unison](https://www.cis.upenn.edu/~bcpierce/unison/) tool is as easy to understand as _rsync_ and has never had any failures in my years of use. The main catch with unison is that you need to identify and exclude files that are constantly being written to by your application, and/or create a script to quiesce the application during sync operations.

Explore this repo for several different approaches to data backups. Restic is the main off-the-shelf tool that I've found as an alternative to CrashPlan for Home. Another tool called Duplicati works well for small savesets (it chokes on larger ones and doesn't generate log output for monitoring). My [secondshot](https://github.com/instantlinux/secondshot)_ tool adds metadata-indexing and monitoring to the _rsnapshot_ method.

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

### The version 1.15.0 upgrade fiasco

The kubeadm update procedure didn't work for 1.13->1.14 upgrade so
when an unknown fault took down my single master, I opted to do a
fresh install of 1.15.0. That led to a multiple-day total outage of
all services. Here are notes that might help others prevent similar
debacles:

* Networking and DNS are fundamental, and can fail silently on a newly
  built cluster. Use a busybox container to ensure you can do DNS
  lookups against the nameserver listed in /etc/resolv.conf after
  generating a new master and worker(s). Do not proceed until you've
  solved any mysteries that prevent this from working (and THIS CAN
  TAKE DAYS on a bare-metal cluster.)

* If you only have a single controller that has failed, don't do anything
  intrusive to it (like, say, the obvious--restoring a backup; this
  totally clobbered my setup). If it's been running for more than a
  couple months, chances are it's got some hard-to-replace
  configurations and the currently available backup/restore procedures
  may not (or probably won't) save you. Build a new one and use the
  old server as reference.

* Switching from flannel to calico 3.8 was fraught with
  problems. Hours into things, I couldn't figure out why coredns
  wouldn't resolve any names from any pod: wound up sticking with
  flannel for the foreseeable future. Also, it's easy to get both
  flannel and calico installed, a major conflict.

* Installation procedure for cert-manager is 100% different from 5
  months ago (in 2022). That took me about 3 hours to resolve. And I'd
  become over-reliant on cert-manager: without valid TLS certificates,
  my local Docker registry wouldn't come up. Without the registry,
  most services wind up in ImagePullBackoff failure state. (Update in
  2024 -- almost services I run are now on docker hub or
  registry.k8s.io, so they depend only on Internet and DNS.)

* When restoring cert-manager, get ingress-nginx working first.

* My efforts to lock down kubernetes security (based mostly on tutorial-
  style procedures found online) backfired big-time: bottom line is that
  if you have to do something manual to get your setup running after
  the community-supplied installer (kubeadm) finishes, then it's quite
  likely whatever script or resource definition you created to automate
  such manual processes *won't* work next time you need to do disaster-
  recovery or routine upgrades. Make sure your kubeadm-config.yaml
  defines all the flags required for the control plane under
  /etc/kubernetes/manifests.

* One thing I'd done that compromised availability in the interest of
  security was to encrypt etcd key-value storage. Make sure to
  practice backup/restore a couple times, and document in an obvious
  place what the restore procedure is and where to get the decyption
  codes. The k8s-cplane ansible playbook here should help.

