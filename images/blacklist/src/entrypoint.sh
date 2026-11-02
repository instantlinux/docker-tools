#! /bin/bash

export PID_FILE=/tmp/rbldnsd.pid
cd $HOMEDIR
echo "[client]
host=$DB_HOST" > .my.cnf
cat /var/run/secrets/mysql-blacklist-user >> .my.cnf
chmod 600 .my.cnf

mkdir -p $CFG_NAME
cd $CFG_NAME
[ -e spammerlist ] || touch spammerlist
[ -e whitelist ] || touch whitelist
if [ ! -e forward ]; then
  echo '\$SOA' 3600 $RBL_DOMAIN $RBL_DOMAIN 0 600 300 86400 300 >forward
  echo '\$NS' 3600 \$NS_SERVERS >>forward
fi

mysql --defaults-file=$HOMEDIR/.my.cnf <<EOT
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`;
USE $DB_NAME;
CREATE TABLE IF NOT EXISTS \`ips\` (
  \`ipaddress\` varchar(40) NOT NULL DEFAULT '',
  \`dateadded\` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  \`reportedby\` varchar(40) DEFAULT NULL,
  \`updated\` datetime ON UPDATE CURRENT_TIMESTAMP,
  \`count\` int NOT NULL DEFAULT 0,
  \`attacknotes\` text,
  \`b_or_w\` char(1) NOT NULL DEFAULT 'b',
  PRIMARY KEY  (\`ipaddress\`),
  KEY \`dateadded\` (\`dateadded\`),
  KEY \`b_or_w\` (\`b_or_w\`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='spammer list';
EOT

( while true; do
    /usr/local/bin/rebuild_rbldns.pl
    sleep 60
  done
) &

exec rbldnsd -f -n -r $HOMEDIR/$CFG_NAME -b 0.0.0.0/53 -p $PID_FILE \
  $RBL_DOMAIN:ip4set:spammerlist,whitelist \
  $RBL_DOMAIN:generic:forward
