## dnsmasq-pxeboot

The dnsmasq server for serving DHCP, DNS, and/or TFTP. This is commonly used to support a PXE boot environment but can also operate as a standalone local DNS or DHCP server.

### Usage

In docker-compose.yml, set the environment variables for your environment.

Mount these two files under /etc/dnsmasq.d/local:

* ethers: Add any MAC addresses for which you want static IP assignments (see [syntax](https://linux.die.net/man/5/ethers))
* hosts: Addentries you want added dnsmasq's DNS service (see [syntax](https://linux.die.net/man/5/hosts))

Mount your PXE boot images and client definitions under /tftpboot/pxelinux.

See the docker-compose.yml file provided here in the source directory; this needs to run on host network with kernel capability CAP_NET_ADMIN, so it will not currently run in Docker Swarm.

Verified to work with a single subnet and with the limited set of DHCP options supported in environment vars defined here. Additional options as defined in the [dnsmasq man page](https://linux.die.net/man/8/dnsmasq) can be specified in dhcpd-options.conf under /etc/dnsmasq.d/local volume mount.

If you only want to service static IP addresses and do not want to provide a pool (e.g. you've got a router or other server already providing DHCP), the DHCP_RANGE variable still has to be defined but you can tell it static-only in this form: "192.168.1.0,static,255.255.255.0".

### Variables

Variable | Default | Description |
-------- | ------- | ----------- |
DHCP_BOOT | pxelinux.0 | PXE-boot filename
DHCP_ENABLE | yes | enable dhcp server
DHCP_RANGE | 192.168.1.101,192.168.1.150 | 
DNS_ENABLE | yes | enable dns server
DNS_SERVER |  | list of (other) DNS servers to send dhcp clients
DOMAIN | example.com | your domain name
IP_FORWARDING | 0 | enable clients' IP forwarding
NTP_SERVER | 0.pool.ntp.org,1.pool.ntp.org | 
SUBNET1_GATEWAY | 192.168.1.1 | gateway IP to send dhcp clients
SUBNET1_INTERFACE | eth0 | serve only on this subnet
SUBNET1_NETMASK | 255.255.255.0 | network mask
TFTP_ENABLE | yes | enable tftp server
TFTP_ROOT | /tftpboot/pxelinux | don't change this
