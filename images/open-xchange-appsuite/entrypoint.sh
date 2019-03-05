#!/bin/bash -e

if [ ! -s /run/secrets/ox-admin-password ] || \
   [ ! -s /run/secrets/ox-db-password ] || \
   [ ! -s /run/secrets/ox-master-password ]; then
  echo "** This container will not run without secrets **"
  echo "** Specify ox-admin-password, ox-db-password, ox-master-password **"
  sleep 10
  exit 1
elif ! nc -z $OX_CONFIG_DB_HOST 3306; then
  echo "** This container cannot reach DB host $OX_CONFIG_DB_HOST **"
  sleep 10
  exit 1
fi
OX_ADMIN_PASSWORD=`cat /run/secrets/ox-admin-password`
OX_DATADIR=/ox/store
OX_ETCBACKUP=/ox/etc
OX_DB_PASSWORD=`cat /run/secrets/ox-db-password`
OX_MASTER_PASSWORD=`cat /run/secrets/ox-master-password`

chown -R open-xchange /var/log/open-xchange $OX_DATADIR

FIRST_TIME=0
if [ -d ${OX_ETCBACKUP}/settings ]; then
  cp -a ${OX_ETCBACKUP}/. /opt/open-xchange/etc/
else
  FIRST_TIME=1
  /opt/open-xchange/sbin/initconfigdb \
    --configdb-dbname=${OX_CONFIG_DB_NAME} \
    --configdb-host=${OX_CONFIG_DB_HOST} \
    --configdb-pass=${OX_DB_PASSWORD} \
    --configdb-port=3306 \
    --configdb-user=${OX_CONFIG_DB_USER} -i
  /opt/open-xchange/sbin/oxinstaller \
    --configdb-dbname=${OX_CONFIG_DB_NAME} \
    --configdb-pass=${OX_DB_PASSWORD} \
    --configdb-readhost=${OX_CONFIG_DB_HOST} \
    --configdb-readport=3306 \
    --configdb-user=${OX_CONFIG_DB_USER} \
    --configdb-writehost=${OX_CONFIG_DB_HOST} \
    --configdb-writeport=3306 \
    --master-pass=${OX_MASTER_PASSWORD} \
    --network-listener-host=localhost \
    --no-license \
    --servermemory ${OX_SERVER_MEMORY} \
    --servername=${OX_SERVER_NAME}
  sed -i \
    -e 's/# com.openexchange.capability.text/com.openexchange.capability.text/1' \
    -e 's/# com.openexchange.capability.spreadsheet/com.openexchange.capability.spreadsheet/1' \
    /opt/open-xchange/etc/documents.properties
fi

/opt/open-xchange/sbin/triggerupdatethemes -u
su -s /bin/bash open-xchange -c /opt/open-xchange/sbin/open-xchange &

if [ "$FIRST_TIME" == 1 ]; then
  while ! /opt/open-xchange/sbin/registerserver \
    --adminuser=${OX_ADMIN_MASTER_LOGIN} \
    --adminpass=${OX_MASTER_PASSWORD} \
    --name=${OX_SERVER_NAME}; do
      echo "--Waiting on registerserver"
      sleep 5
  done;

  /opt/open-xchange/sbin/registerfilestore \
    --adminpass=${OX_MASTER_PASSWORD} \
    --adminuser=${OX_ADMIN_MASTER_LOGIN} \
    --storepath=file:${OX_DATADIR} \
    --storesize=1000000
  /opt/open-xchange/sbin/registerdatabase \
    --adminpass=${OX_MASTER_PASSWORD} \
    --adminuser=${OX_ADMIN_MASTER_LOGIN} \
    --dbuser=${OX_CONFIG_DB_USER} \
    --dbpasswd=${OX_DB_PASSWORD} \
    --hostname=${OX_CONFIG_DB_HOST} \
    --master=true \
    --name=oxdatabase
  while ! /opt/open-xchange/sbin/createcontext \
    --access-combination-name=groupware_standard \
    --addmapping=defaultcontext \
    --adminpass=${OX_MASTER_PASSWORD} \
    --adminuser=${OX_ADMIN_MASTER_LOGIN} \
    --contextid=${OX_CONTEXT_ID} \
    --displayname="Context Admin" \
    --email=${OX_CONTEXT_ADMIN_EMAIL} \
    --givenname=Admin \
    --password=${OX_ADMIN_PASSWORD} \
    --quota=1024 \
    --surname=Admin \
    --username=${OX_CONTEXT_ADMIN_LOGIN}; do
      echo "--waiting on createcontext"
      sleep 5
  done
  cp -a /opt/open-xchange/etc/. ${OX_ETCBACKUP}
fi
apachectl -d /etc/apache2 -k start
exec bash -c 'while [ 1 == 1 ]; 
  do tail -500f /var/log/open-xchange/open-xchange.log.0;
  echo Have patience, waiting for server to start; sleep 5; done'
