## weewx
[![](https://img.shields.io/docker/v/instantlinux/weewx?sort=date)](https://hub.docker.com/r/instantlinux/weewx/tags "Version badge") [![](https://img.shields.io/docker/image-size/instantlinux/weewx?sort=date)](https://github.com/instantlinux/docker-tools/-/blob/main/images/weewx "Image badge") ![](https://img.shields.io/badge/platform-amd64%20arm64%20arm%2Fv6%20arm%2Fv7-blue "Platform badge") [![](https://img.shields.io/badge/dockerfile-latest-blue)](https://gitlab.com/instantlinux/docker-tools/-/blob/main/images/weewx/Dockerfile "dockerfile")

Weather station software WeeWX

This is a multi-architecture image for AMD, ARM, Intel, Raspberry Pi: see the platform badge above for supported platforms. This includes WeeGreen skin; see the [live site](http://wx.ci.net) for an example.

### Usage

First create secrets as defined below, in /var/adm/admin/secrets.
Ensure your weather station device (usually /dev/ttyUSB0) is
read/writeable by user "weewx" (uid 2071) or by gid 20 (group
"dialout") via udev rules--all other parameters can be set as below.

Then deploy this service with docker-compose; see the example
docker-compose.yml. Available environment variables are below.

To create the external-facing web site which runs as a separate
containerized service, use the simple nginx.conf configuration
provided [here](https://github.com/instantlinux/docker-tools/blob/main/images/weewx/nginx.conf) under docker swarm with the docker-compose-nginx.yml stack
definition, or (even easier) under Kubernetes deploy the
[wx-nginx.yaml](https://github.com/instantlinux/docker-tools/blob/main/k8s/wx-nginx.yaml) resource definition.

### Variables

| Variable | Default value | Description |
| -------- | ------------- | ----------- |
| AIRLINK_HOST | | local hostname or IP of AirLink AQI sensor|
| ALTITUDE | "100, foot" | elevation of station |
| LATITUDE | 50.00 | coordinates |
| LONGITUDE | -80.00 | coordinates  |
| DB_BINDING_SUFFIX | mysql | suffix for db binding stanzas |
| DB_DRIVER | weedb.mysql | database driver |
| DB_HOST | db | hostname of db |
| DB_NAME | weewx_a | name of main archive database |
| DB_NAME_FORECAST | weewx_f | name of forecast database (deprecated) |
| DB_USER | weewx | username for db |
| DEVICE_PORT | /dev/ttyUSB0 | serial-port device |
| HTML_ROOT | /var/www/weewx | tmp directory for generating html/png images |
| LOCATION | "Anytown, USA" | location to display in banner |
| LOGGING_INTERVAL | 300 | sampling interval |
| OPERATOR | "Al Roker" | your name |
| OPTIONAL_ACCESSORIES | False | whether solar, UV or AQI sensors installed |
| RAIN_YEAR_START | 7 | month to start collecting annual rain data |
| RAPIDFIRE | True | enable Weather Underground realtime updates |
| RSYNC_DEST | /usr/share/nginx/html | rsync destination path |
| RSYNC_HOST | web01 | rsync destination host |
| RSYNC_PORT | 22 | rsync ssh port |
| RSYNC_USER | wx | rsync username |
| SKIN | Standard | skin to enable (Seasons, Standard, WeeGreen) |
| STATION_FEATURES | "fan-aspirated shield" | added features |
| STATION_ID | unset | Weather Underground station ID |
| STATION_MODEL | 6152 | model number of station |
| STATION_TYPE | Vantage | station type (see [usersguide](http://www.weewx.com/docs/usersguide.htm) |
| STATION_URL | | URL for public registration at weewx.com, if desired |
| SYSLOG_DEST | /var/log/messages | Syslog file or TCP dest (@@host:port) |
| TZ | US/Eastern | Local timezone |
| TZ_CODE | 10 | Davis VantagePro timezone code see [index](https://www.manualslib.com/manual/586601/Davis-Vantage-Pro.html?page=39) |
| WEBCAM_URL | (generic) | Suggest http://www.wunderground.com/webcams/<yourID>/1/show.html |
| WEEK_START | 6 | day of week to start weekly data (0 = Mon) |
| WX_USER | weewx | run-as username |
| XTIDE_LOCATION | unset | xtide setting, see [index](http://tides.mobilegeographics.com/) |

You can volume-mount a different skin to a subdirectory of /home/weewx/skins if you prefer one that isn't already included.

If `OPTIONAL_ACCESSORIES` is specified, you must upgrade database (see below).

### Secrets

Secret | Description
------ | -----------
weewx-db-password | database password for MySQL
weewx-rsync-sshkey | private ssh key for rsync upload
weewx-wunderground-apikey | API key for Wunderground.com
weewx-wunderground-password | password for Wunderground.com

### Upgrading

#### To 4.x

Version 4 supports an optional new database schema called `wview_extended`. The official [WeeWX Upgrade Guide](http://www.weewx.com/docs/upgrading.htm) inexplicably omits any information about how to migrate your database; here's a rough outline of what you need to do if you have existing 3.x data and want to migrate (in order to  gain new features such as AQI):

* Backup your current database
* Create a blank database `weewx_a_new` with same access grants
* Launch the docker container with 4.x and invoke `~weewx/bin/wee_database --reconfigure`
* After the above operation completes (takes many minutes, could be over an hour for several years' worth data), stop any running copy of weewx
* Replace database `weewx_a` with contents of `weewx_a_new` (for mariadb/mysql, you have to dump/import the data)
* Make sure only one table `archive` exists in the database: `reconfigure` only generates that table, not the 50+ daily summary tables; if present they are likely to trigger a ViolatedPrecondition exception
* Restart weewx and wait another lengthy period for it to automatically rebuild the daily summary tables (you can track progress using `SELECT COUNT(*) FROM archive_day_outTemp;`)

Because the new schema contains almost twice as many columns, future backups will require almost twice as much storage.

### Notes

This can run in kubernetes but not in swarm because it needs to attach
the weather stations as devices. Kubernetes may be more secure than
docker-compose, because docker-compose requires that secrets be stored
as plain-text files, but the container needs to be run in privileged
mode to access the weather-station device(s).

Example [docker-compose.yml](https://github.com/instantlinux/docker-tools/blob/main/images/weewx/docker-compose.yml), [helm chart](https://github.com/instantlinux/docker-tools/tree/main/images/weewx/helm) and [kubernetes.yaml](https://github.com/instantlinux/docker-tools/blob/main/images/weewx/kubernetes.yaml)
files are included here. See the Makefile in [k8s](https://github.com/instantlinux/docker-tools/blob/main/k8s/Makefile) to launch with kubernetes.

Tide info for US locations is generated by a library called
[xtide](http://www.flaterco.com/xtide/); there's no binary package for it in Alpine Linux
so a somewhat complicated set of commands is included here to package
it from source within Dockerfile.

Sadly, forecasts are no longer supported. It was once possible to
integrate weather-service forecasts with the observational data
collected and uploaded by this software. The online API was
discontinued in a September 2018 decision by IBM after the company
acquired Weather Underground. Also, the weewx-forecast module never
got updated from 3.3.2 to support python3.

Output logging from weewx is a bit of a mess: when running
in foreground, a lot of verbose clutter appears on stdout; the
real logs go to syslog and there's no configuration method to
send these elsewhere (like stdout to conform to Docker's logging
standard). So the SYSLOG_DEST environment variable provided here
can provide a way to send proper logging (via the rsyslogd
process included in this image) to a central syslog service.

### Contributing

If you want to make improvements to this image, see [CONTRIBUTING](https://github.com/instantlinux/docker-tools/blob/main/CONTRIBUTING.md).

[![](https://img.shields.io/badge/license-GPL--3.0-red.svg)](https://choosealicense.com/licenses/gpl-3.0/ "License badge") [![](https://img.shields.io/badge/code-weewx%2Fweewx-blue.svg)](https://github.com/weewx/weewx "Code repo")
