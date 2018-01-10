## dropbox

[![](https://images.microbadger.com/badges/version/instantlinux/dropbox.svg)](https://microbadger.com/images/instantlinux/dropbox "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/dropbox.svg)](https://microbadger.com/images/instantlinux/dropbox "Image badge") [![](https://images.microbadger.com/badges/commit/instantlinux/dropbox.svg)](https://microbadger.com/images/instantlinux/dropbox "Commit badge")

Dropbox client under Debian stretch.

### Usage

Mount your sync contents as /home/user/Dropbox, and define a state directory as /home/user/.dropbox. Set environment variable UID to match your personal Linux numeric user ID.

When you first launch this, use the following command to get the access token:
```
docker logs -f (containerid)
  ...
This computer isn't linked to any Dropbox account...
Please visit https://www.dropbox.com/cli_link_nonce?nonce=f3566e51f010ab5def337e45b319a07a to link this device.
```
Log into Dropbox and click the token URI as shown in the example output above; files will be kept in sync between your host's mounted file contents and your account on the Dropbox service.

A docker-compose.yml example is included here in this source directory.

### Variables

Variable | Default | Description
-------- | ------- | -----------
UID | 1000 | Linux user ID

[![](https://images.microbadger.com/badges/license/instantlinux/dropbox.svg)](https://microbadger.com/images/instantlinux/dropbox "License badge")
