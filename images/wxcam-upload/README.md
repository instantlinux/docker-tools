## wxcam-upload
[![](https://images.microbadger.com/badges/version/instantlinux/wxcam-upload.svg)](https://microbadger.com/images/instantlinux/wxcam-upload "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/wxcam-upload.svg)](https://microbadger.com/images/instantlinux/wxcam-upload "Image badge") [![](https://images.microbadger.com/badges/commit/instantlinux/wxcam-upload.svg)](https://microbadger.com/images/instantlinux/wxcam-upload "Commit badge")

This wraps an upload script along with proftpd for publishing still images from network-attached webcams to the Weather Underground webcam server.

### Usage

Sign up with Weather Underground to get a user login, and set up one or more webcams. Add secrets to your Docker Swarm installation (or define them as plain-text files), and set parameters as defined below. An example compose file is provided here in docker-compose.yml.

### Variables

This image is based on instantantlinux/proftpd; see the variables there as well as these.

Variable | Default | Description |
-------- | ------- | ----------- |
ANONYMOUS_DISABLE | on | no downloads from local ftp
CAMS | cam1 | names of webcams (space-delimited list)
INTERVAL | 5 | interval for transmitting to Weather Underground (minutes)
PASV_MAX_PORT | 30090 | docker-host port number range
PASV_MIN_PORT | 30081 |
UPLOAD_HOSTNAME | webcam.wunderground.com | destination of image uploads
UPLOAD_PASSWORD_SECRET | wunderground-user-password | name of secret for API
UPLOAD_PATH | /home/wx/upload | root of uploaded files
UPLOAD_USERNAME | required | Weather Underground API user
WXUSER_NAME | wx | username for wx upload
WXUSER_PASSWORD_SECRET | wxuser-password-hashed | name of secret for ftp user
WXUSER_UID | 2060 | uid of wx files
TZ | UTC | timezone

### Secrets

Secret | Description
------ | -----------
wunderground-user-password | credential for Weather Underground API
wxcam-password-hashed | hashed password of 
wxuser-password-hashed | hashed password of ftp upload user

[![](https://images.microbadger.com/badges/license/instantlinux/wxcam-upload.svg)](https://microbadger.com/images/instantlinux/wxcam-upload "License badge")
