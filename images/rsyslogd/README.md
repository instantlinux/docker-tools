## rsyslogd

Run your central rsyslog in a high-availability container on top of shared storage. Then send all that into Splunk or wherever.

Why is this image customized? I couldn't find a stock Docker rsyslogd image that includes logrotate; the Docker community seems to have run amok splitting out trivial tools that really belong together. This also includes the rsyslog-mysql module (boosts image size from 7.4MB to 12.7MB).

### Usage

Set up a load balancer with your desired port number and aim it at this. Put your /etc/rsyslog.d and /etc/logrotate.d customizations into read-only volume mounts. There's really not much to this.

An example compose file is provided here in docker-compose.yml.
