#!/bin/bash
exec /usr/sbin/apache2ctl -D FOREGROUND >/dev/null 2>&1
