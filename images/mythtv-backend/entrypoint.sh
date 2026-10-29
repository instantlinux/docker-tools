#! /bin/bash -e
[ -z "$LOCALHOSTNAME" ] && LOCALHOSTNAME=$HOSTNAME
MYTHHOME=/home/mythtv

if [ -e /run/secrets/mythtv-db-password ]; then
  DBPASSWORD=$(cat /run/secrets/mythtv-db-password)
fi

# Substitute environment variables in config.xml
cp /etc/mythtv/config.xml /tmp
sed /tmp/config.xml \
    -e "s/{{ DBNAME }}/$DBNAME/" \
    -e "s/{{ DBPASSWORD }}/$DBPASSWORD/" \
    -e "s/{{ DBSERVER }}/$DBSERVER/" \
    -e "s/{{ LOCALHOSTNAME }}/$LOCALHOSTNAME/" \
    > /etc/mythtv/config.xml
chmod 600 /etc/mythtv/config.xml

for retry in $(seq 1 10); do
  /usr/bin/mythbackend || echo Unexpected exit retry=$retry
  sleep 60
done
