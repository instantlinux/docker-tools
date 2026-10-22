#!/bin/sh -e
cat /etc/os-release
rest-server --version
exec rest-server --path "$DATA_DIRECTORY" --htpasswd-file /run/secrets/$PASS_SECNAME
