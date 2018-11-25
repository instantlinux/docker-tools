## k8s

Kubernetes is a circa-2014 successor to Google's circa-2003 Borg
project. Docker Inc. created a rival technology, Docker Swarm, which
dominated my efforts in this repo until I finally concluded that by
mid-2017 the vastly harder-to-use / harder-to-learn Kubernetes
technology had eliminated Swarm from meaningful contention in the
enterprise market.

This repo is an attempt to make Kubernetes more approachable for any
user who wants to get started easily, with a real cluster (not just
a single-instance minikube setup).

### Requirements and cost

Set up three or more bare-metal quad-core servers or VMs with at least
a couple gigabytes of RAM each. At present this is limited to a single
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
master.domain.com
kube1.domain.com
kube2.domain.com
kube3.domain.com
```

Then run the ansible playbook to install docker and configure
nodes. The playbook can generate LUKS-encrypted volume mounts for your
data; the ansible playbook includes a role that can reference a remote
volume (I use sshfs for this) that holds the keys under a /masterlock
directory. Create a group_vars/k8s_nodes.yml file that contains definitions
like this:

```
luks_vg: vg01

luks_volumes:
  volkube:
    inodes: 10000
    path: /var/lib/docker/k8s-volumes
    size: 100000
    vg: "{{ luks_vg }}"
```

Launch the playbook thus:

```
ansible-playbook k8s-node.yml
```
Kubernetes should be up and running at this point, with a bare-minimum
configuration.

Set up a local repo to define environment variables. Kubernetes resources
here are defined in the native YAML format but with one extension: they
are parameterized by the use of _envsubst_ which allows values to be
passed in as shell environment variables in the form $VARIABLE_NAME.
Choose a namespace and a 32-byte encryption key and define them thus:
```
export EDITOR=vi
export ENCRYPTION_KEY=3zQ#LgGGc9R&9z5@Z^68H6Gz6Q7vQ1z2
export K8S_NAMESPACE=mynamespace
```

Set a symlink from a directory under this one called secrets to a
subdirectory in your local administrative repo. This is where you will
store kubernetes secrets, encrypted by a tool called _sekret_.

Then invoke the following in this directory:
```
make install
```
This will add flannel networking, the dashboard, an nginx ingress
load-balancer, helm and sekret. Create directories for persistent
volumes for each node:
```
for node in kube1 kube2 kube3; do
  NODE=$node make persistent_dirs
done
```

Add the token generated at tail end of the above command to your
.kube/config file. Verify you can reach the dashboard after running
_kubectl proxy_ at http://localhost:8001 with the .kube/config file.

Check /var/log/syslog, and the output logs of pods that you can access
via the Kubernetes console, to troubleshoot problems.

### Status

This section of the repo is very much alpha, it's intended to help get
started with kubectl, helm, letsencrypt and sekret but there will
still be a learning curve to get the volume mounts set up, permissions
set and application configurations fully working.
