# !/bin/bash

unison
[ $? != 0 ] && echo "`date --rfc-3339=seconds` Error during unison run" \
  >> /var/log/unison/unison.log
