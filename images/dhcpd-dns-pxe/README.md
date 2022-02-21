## dhcpd-dns-pxe
[![](https://img.shields.io/docker/v/instantlinux/dhcpd-dns-pxe?sort=date)](https://hub.docker.com/r/instantlinux/dhcpd-dns-pxe/tags "Version badge") [![](https://img.shields.io/docker/image-size/instantlinux/dhcpd-dns-pxe?sort=date)](https://github.com/instantlinux/docker-tools/-/blob/main/images/dhcpd-dns-pxe "Image badge") ![](https://img.shields.io/badge/platform-amd64%20arm64%20arm%2Fv6%20arm%2Fv7-blue "Platform badge") [![](https://img.shields.io/badge/dockerfile-latest-blue)](https://gitlab.com/instantlinux/docker-tools/-/blob/main/images/dhcpd-dns-pxe/Dockerfile "dockerfile")

Serve DNS and DHCP from one or more small Alpine Linux container(s). This
supplies DNS and tftp (for network PXE booting) using dnsmasq, and
DHCP using your choice of the original ISC dhcpd or the newer
dnsmasq. Any of the three services can be enabled or disabled. 

### Usage

In kubernetes.yaml / docker-compose.yml, set the environment variables for your environment.

Mount these under /etc:

* /etc/dhcpd.d/local/reserve-<net>.conf: Add any hardware MAC addresses for which you want static IP assignments (see [dhcpd man page](https://linux.die.net/man/5/dhcpd.conf))
* /etc/dhcpd.d/local/ranges: Optional non-overlapping range definitions as noted below
* /etc/dnsmasq.d/local/hosts: Add entries you want added dnsmasq's DNS service (see [syntax](https://linux.die.net/man/5/hosts))

Mount your PXE boot images and client definitions under /tftpboot/pxelinux.

See the kubernetes.yaml provided here. If you're using Swarm, see the docker-compose.yml file provided here in the source directory; this needs to run on host network with kernel capability CAP_NET_ADMIN, so it will not currently run in Docker Swarm. (You can run a single instance of this via _docker run_ or _docker-compose_.) This repo has complete instructions for
[building a kubernetes cluster](https://github.com/instantlinux/docker-tools/blob/main/k8s/README.md) where you can launch with [helm](https://github.com/instantlinux/docker-tools/tree/main/images/dhcpd-dns-pxe/helm), or [kubernetes.yaml](https://github.com/instantlinux/docker-tools/blob/main/images/dhcpd-dns-pxe/kubernetes.yaml) using _make_ and customizing [Makefile.vars](https://github.com/instantlinux/docker-tools/blob/main/k8s/Makefile.vars) after cloning this repo:
~~~
git clone https://github.com/instantlinux/docker-tools.git
cd docker-tools/k8s
make dhcpd-dns-pxe
~~~

You can build a failsafe cluster of DHCP servers under kubernetes using the kubernetes.yaml definition here. Define a ConfigMap with non-overlapping range definitions such as "192.168.1.32 192.168.1.63", "192.16.1.64 192.168.1.95", "192.168.1.96 192.168.1.127" for a set of 3 replicas. If a replica goes down, the others will continue to assign addresses. They won't conflict thanks to the way DHCP protocol works; a client will use the first address offered and ignore any additional offers from the server pool. If a blank range is specified, the dhcp server will offer only reserved MAC/IP assignments.

Verified to work with a single subnet and with the limited set of DHCP/DNS options supported in environment vars defined here. Additional options as defined in the [dnsmasq man page](https://linux.die.net/man/8/dnsmasq) can be specified as any .conf file under /etc/dnsmasq.d/local volume mount, and for dhcpd as any .conf file under /etc/dhcpd.d/local.

I don't use the DHCP feature of dnsmasq; its software configuration
is hugely different from ISC and much more difficult to customize if
you've been using ISC all along. If you've been using dnsmasq all
along, simply set variable DHCP_ENABLE=no and volume-mount your configuration as /etc/dnsmasq.d/local/dhcpd-options.conf; dnsmasq will serve
DHCP on port 67 if you have any such options specified.

### Variables

These variables can be passed to the image from kubernetes.yaml or docker-compose.yml as needed:

Variable | Default | Description |
-------- | ------- | ----------- |
DHCP_BOOT | pxelinux.0 | PXE-boot filename
DHCP_ENABLE | yes | enable dhcp server
DHCP_LEASE_PATH | /var/lib/misc | don't change this
DHCP_LEASE_TIME | 3600 | default lease time
DHCP_NETBIOS_NAME_SERVERS | | netBIOS name servers
DHCP_RANGE | | dynamic IP pool, e.g. "192.168.1.101 192.168.1.150"
DNS_ENABLE | yes | enable dns server
DNS_SERVER | | list of (other) DNS servers to send dhcp clients
DNS_UPSTREAM | 8.8.8.8 | upstream DNS server for queries (e.g. your ISP)
DOMAIN | example.com | your domain name
IP_FORWARDING | false | enable clients' IP forwarding
LISTEN_ADDRESS | | bind to IP address
MAX_LEASE_TIME | 14400 | maximum lease time
NTP_SERVER | 0.pool.ntp.org,1.pool.ntp.org | 
PORT_DNSMASQ_DNS | 53 | port number for DNS
SUBNET1_GATEWAY | 192.168.1.1 | gateway IP to send dhcp clients
SUBNET1_INTERFACE | eth0 | serve only on this subnet
SUBNET1_NETMASK | 255.255.255.0 | network mask
TFTP_ENABLE | yes | enable tftp server
TFTP_ROOT | /tftpboot/pxelinux | don't change this

### Contributing

If you want to make improvements to this image, see [CONTRIBUTING](https://github.com/instantlinux/docker-tools/blob/main/CONTRIBUTING.md).

[![](https://img.shields.io/badge/license-Apache--2.0-red.svg)](https://choosealicense.com/licenses/apache-2.0/ "License badge") [![](https://img.shields.io/badge/code-isc%2Fdhcp-blue.svg)](https://source.isc.org/git/dhcp.git "Code repo") [![](https://img.shields.io/badge/code-thekelleys%2Fdnsmasq-blue.svg)](http://thekelleys.org.uk/gitweb/?p=dnsmasq.git "Code repo")
