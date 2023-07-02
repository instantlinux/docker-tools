#!/bin/bash -e

if [ ! -f /etc/timezone ] && [ ! -z "$TZ" ]; then
  # At first startup, set timezone
  cp /usr/share/zoneinfo/$TZ /etc/localtime
  echo $TZ >/etc/timezone
fi

if [ ! -s $BUILD_DIR/.docker/config.json ]; then
  umask 077
  mkdir -p /dev/shm/.docker
  echo -e '{ "auths": {\n  }\n}' > /dev/shm/.docker/config.json
  ln -s /dev/shm/.docker $BUILD_DIR/
fi

. /usr/local/bin/docker-entrypoint.sh
