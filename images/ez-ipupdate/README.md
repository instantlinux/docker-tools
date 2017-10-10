## ez-ipupdate
[![](https://images.microbadger.com/badges/version/instantlinux/ez-ipupdate.svg)](https://microbadger.com/images/instantlinux/ez-ipupdate "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/ez-ipupdate.svg)](https://microbadger.com/images/instantlinux/ez-ipupdate "Image badge")

Dynamic-DNS client - set up for Docker Swarm to ensure it's always running.

First create a secret:

    echo user:pw | docker secret create ez-ipupdate-user -

Then deploy this service, see the example docker-compose.yml. Available
environment variables are:

| Variable | Description |
| -------- | ----------- |
| HOST | the DNS name whose address you want kept up to date |
| INTERVAL | poll interval |
| IPLOOKUP_URI | a URI that returns the IPv4 address to be assigned |
| SERVICE_TYPE | DNS vendor, see [available services](http://leaf.sourceforge.net/doc/bucu-ezipupd.html) |
| USER_SECRET | Name of the Docker secret to deploy |

