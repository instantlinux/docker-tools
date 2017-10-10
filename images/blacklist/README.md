## DNS blacklist for spamassassin
[![](https://images.microbadger.com/badges/version/instantlinux/blacklist.svg)](https://microbadger.com/images/instantlinux/blacklist "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/blacklist.svg)](https://microbadger.com/images/instantlinux/blacklist "Image badge")

This is based on [Running Your Own RBL DNS Blacklist](http://www.blue-quartz.com/rbl/) using the Debian rbldnsd
package adapted from scripts published by Herb Rubin some years
ago. This attempts to counter large-scale botnets (with hundreds of
thousands of scattered IP addresses) that spammers use to bypass the
well-known DNSBL sites. We do this by examining known-spam messages'
Received headers, and inserting their source IP addresses into a local
MySQL table, almost immediately blacklisting against multiple uses of
any given source IP. This tool maintains that table and provides a
local DNSBL which you can add to Spamassassin's rules. To make the
most use of it, set up honeypot email addresses separate from your
primary users' addresses; greylisting unknown senders for several
minutes will add to this protection.

### Usage
Before running it, grant access to a mysql user thus:
~~~bash
    USER=blacklister
    PSWD=xxx
    mysql> GRANT SELECT,UPDATE,INSERT,CREATE ON `blacklist`.* TO
     '$USER'@'10.%' IDENTIFIED BY '$PSWD';
~~~
Add a mysql-blacklist-user that contains the $PSWD you've set:
~~~bash
    # docker secret create mysql-blacklist -
    user=blacklister
    password=$PSWD
~~~
Decide on a subdomain name, such as blacklist.yourdomain.com. See
docker-compose.yml for an example; set that name as an environment variable
RBL_DOMAIN. To delegate to this subdomain, list hosts where you'll
be running this in environment variable NS_SERVERS (if you're running
a swarm cluster, this will be the DNS names of the cluster nodes).

In the local.cf file for spamassassin (separate Docker image), define
these rules for your local blacklist:

~~~
score    HONEY_RCVD_IN_RBL  4.5
header   HONEY_RCVD_IN_RBL  eval:check_rbl('bl', 'blacklist.yourdomain.com.', '127.0.0.2')
describe HONEY_RCVD_IN_RBL  Seen in rbldnsd by honeypot address
tflags   HONEY_RCVD_IN_RBL  net
reuse    HONEY_RCVD_IN_RBL

(Below items are performed by scripts in postfix-python image.)

Then to add new IPs into the blacklist, set up procmail to run the
honeypot-ip.py parser script (included here under src directory) to
insert into the MySQL ips table upon receipt of any known spam message.
Example:
~~~bash
    :0fw
    #| /usr/local/bin/honeypot-ip.py --db-config ~/.my.cnf -q \
      --honeypot honeyforbees@instantlinux.net \
      --relay 'by mx-caprica.?\.easydns\.com' --cidr-min-size 32
~~~
Add a .my.cnf file with db credentials:
~~~
    [client]
    host=xdb00
    database=blacklist
    user=blacklist
    password=xxx
~~~
This script can also be invoked as a spamfilter under postfix; use
the --pipe-stdout command option for that use case.

### Variables
| Variable | Default | Description |
| -------- | ------- | ----------- |
| CFG_NAME | dsbl | config name (default: dsbl) |
| DB_NAME | blacklist | database name (blacklist) |
| DB_HOST | dbhost | database host or IP (dbhost) |
| DB_USER | blacklister | db user (blacklister) |
| HOMEDIR | /var/lib/rbldns | home directory |
| NS_SERVERS | 127.0.0.1 | upstream nameservers having NS records |
| RBL_DOMAIN | blacklist.mydomain.com | domain name to serve |
| TZ | US/Pacific | time zone |
| USERNAME | rbldns | username to run as |
