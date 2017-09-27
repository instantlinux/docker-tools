## dhcpd-dns-pxe

Serve DNS and DHCP from a small Alpine Linux container. This has
supplies DNS and tftp (for network PXE booting) using dnsmasq, and
DHCP using your choice of the original ISC dhcpd or the newer
dnsmasq.

The ISC dhcpd server, along with dnsmasq for serving DNS and tftp. Any
of the three services can be enabled or disabled. 

### Usage

In docker-compose.yml, set the environment variables for your environment.

Mount these two files under /etc:

* dhcpd.d/reserve-<net>.conf: Add any hardware MAC addresses for which you want static IP assignments (see [dhcpd man page](https://linux.die.net/man/5/dhcpd.conf))
* dnsmasq.d/hosts: Add entries you want added dnsmasq's DNS service (see [syntax](https://linux.die.net/man/5/hosts))

Mount your PXE boot images and client definitions under /tftpboot/pxelinux.

See the docker-compose.yml file provided here in the source directory; this needs to run on host network with kernel capability CAP_NET_ADMIN, so it will not currently run in Docker Swarm.

Verified to work with a single subnet and with the limited set of DHCP/DNS options supported in environment vars defined here. Additional options as defined in the [dnsmasq man page](https://linux.die.net/man/8/dnsmasq) can be specified as any .conf file under /etc/dnsmasq.d volume mount, and for dhcpd as any .conf file under /etc/dhcpd.d.

I don't use the DHCP feature of dnsmasq; its software configuration
is hugely different from ISC and much more difficult to customize if
you've been using ISC all along. If you've been using dnsmasq all
along, simply set variable DHCP_ENABLE=no and volume-mount your configuration as /etc/dnsmasq.d/dhcpd-options.conf; dnsmasq will serve
DNS on port 67 if you have any such options specified.

### Variables

Variable | Default | Description |
-------- | ------- | ----------- |
DHCP_BOOT | pxelinux.0 | PXE-boot filename
DHCP_ENABLE | yes | enable dhcp server
DHCP_LEASE_PATH | /var/lib/misc | don't change this
DHCP_LEASE_TIME | 3600 | default lease time
DHCP_RANGE | | dynamic IP pool, e.g. "192.168.1.101 192.168.1.150"
DNS_ENABLE | yes | enable dns server
DNS_SERVER | | list of (other) DNS servers to send dhcp clients
DNS_UPSTREAM | 8.8.8.8 | upstream DNS server for queries (e.g. your ISP)
DOMAIN | example.com | your domain name
IP_FORWARDING | false | enable clients' IP forwarding
LISTEN_ADDRESS | | bind to IP address
NETBIOS_NAME_SERVERS | | netBIOS name servers
NTP_SERVER | 0.pool.ntp.org,1.pool.ntp.org | 
PORT_DNSMASQ_DNS | 53 | port number for DNS
SUBNET1_GATEWAY | 192.168.1.1 | gateway IP to send dhcp clients
SUBNET1_INTERFACE | eth0 | serve only on this subnet
SUBNET1_NETMASK | 255.255.255.0 | network mask
TFTP_ENABLE | yes | enable tftp server
TFTP_ROOT | /tftpboot/pxelinux | don't change this
