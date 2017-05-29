# !/bin/sh

unison
if [ $? != 0 ]; then
  echo "`date --rfc-3339=seconds` Error during unison run" \
   >> /var/log/unison/unison.log
else
  echo "`date --rfc-2822` ok" > /var/log/unison/unison-status.txt
fi
