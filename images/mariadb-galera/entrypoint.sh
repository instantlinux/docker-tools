#!/bin/bash
set -e

# if command starts with an option, prepend mysqld
if [ "${1:0:1}" = '-' ]; then
  CMDARG="$@"
fi

[ -z "$TTL" ] && TTL=10
mkdir -p /var/log/mysql && chown mysql /var/log/mysql

if [ -z "$CLUSTER_NAME" ]; then
  echo >&2 'Error:  You need to specify CLUSTER_NAME'
  exit 1
fi

[ -f /root/my.cnf ] && cp /root/my.cnf /etc/mysql/ && rm /root/my.cnf
mkdir -p /etc/mysql/my.cnf.d

# Get config
DATADIR="$("mysqld" --verbose --help 2>/dev/null | awk '$1 == "datadir" { print $2; exit }')"
echo "Content datadir=$DATADIR:"
ls -al $DATADIR
mkdir -p /run/mysqld && chown mysql.mysql /run/mysqld

if [ -z "$MYSQL_ROOT_PASSWORD" -a -f /run/secrets/mysql-root-password ]; then
  MYSQL_ROOT_PASSWORD=`cat /run/secrets/mysql-root-password`
fi

INITIALIZED=0
if [ ! -s "$DATADIR/mysql/user.MYD" ]; then
    INITIALIZED=1
    if [ -z "$MYSQL_ROOT_PASSWORD" -a -z "$MYSQL_ALLOW_EMPTY_PASSWORD" -a -z "$MYSQL_RANDOM_ROOT_PASSWORD" ]; then
        echo >&2 'error: database is uninitialized and password option is not specified '
        echo >&2 '  You need to specify one of MYSQL_ROOT_PASSWORD, MYSQL_ALLOW_EMPTY_PASSWORD and MYSQL_RANDOM_ROOT_PASSWORD'
        exit 1
    fi
    mkdir -p "$DATADIR"
    chown -R mysql:mysql "$DATADIR"

    echo 'Running mysql_install_db'
    OPTS="--user=mysql --datadir=$DATADIR --wsrep-cluster-address=gcomm://"
    mysql_install_db $OPTS --rpm
    echo 'Finished mysql_install_db'

    mysqld $OPTS --skip-networking &
    pid="$!"

    mysql=( mysql --protocol=socket -uroot )

    for i in {30..0}; do
      if echo 'SELECT 1' | "${mysql[@]}" &> /dev/null; then
        break
      fi
      echo 'MySQL init process in progress...'
      sleep 1
    done
    if [ "$i" = 0 ]; then
      echo >&2 'MySQL init process failed.'
      exit 1
    fi

    # sed is for https://bugs.mysql.com/bug.php?id=20545
    mysql_tzinfo_to_sql /usr/share/zoneinfo | sed 's/Local time zone must be set--see zic manual page/FCTY/' | "${mysql[@]}" mysql
    if [ ! -z "$MYSQL_RANDOM_ROOT_PASSWORD" ]; then
      MYSQL_ROOT_PASSWORD="$(pwmake 128)"
      echo "Generated root_password=$MYSQL_ROOT_PASSWORD"
    fi
    "${mysql[@]}" <<-EOSQL
      -- What's done in this file shouldn't be replicated
      --  or products like mysql-fabric won't work
      SET @@SESSION.SQL_LOG_BIN=0;
      DELETE FROM mysql.user ;
      CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;
      GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;
      CREATE USER 'xtrabackup'@'localhost' IDENTIFIED BY '$XTRABACKUP_PASSWORD';
      GRANT RELOAD,LOCK TABLES,REPLICATION CLIENT ON *.* TO 'xtrabackup'@'localhost';
      GRANT REPLICATION CLIENT ON *.* TO monitor@'%' IDENTIFIED BY 'monitor';
      DROP DATABASE IF EXISTS test ;
      FLUSH PRIVILEGES ;
EOSQL
    if [ ! -z "$MYSQL_ROOT_PASSWORD" ]; then
      mysql+=( -p"${MYSQL_ROOT_PASSWORD}" )
    fi

    if [ "$MYSQL_DATABASE" ]; then
      echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` ;" | "${mysql[@]}"
      mysql+=( "$MYSQL_DATABASE" )
    fi

    if [ "$MYSQL_USER" -a "$MYSQL_PASSWORD" ]; then
      echo "CREATE USER '"$MYSQL_USER"'@'%' IDENTIFIED BY '"$MYSQL_PASSWORD"' ;" | "${mysql[@]}"

      if [ "$MYSQL_DATABASE" ]; then
        echo "GRANT ALL ON \`"$MYSQL_DATABASE"\`.* TO '"$MYSQL_USER"'@'%' ;" | "${mysql[@]}"
      fi

      echo 'FLUSH PRIVILEGES ;' | "${mysql[@]}"
    fi

    if [ ! -z "$MYSQL_ONETIME_PASSWORD" ]; then
      "${mysql[@]}" <<-EOSQL
        ALTER USER 'root'@'%' PASSWORD EXPIRE;
EOSQL
    fi
    if ! kill -s TERM "$pid" || ! wait "$pid"; then
      echo >&2 'MySQL init process failed.'
      exit 1
    fi

    echo
    echo 'MySQL init process done. Ready for start up.'
    echo
fi
chown -R mysql:mysql "$DATADIR"

function join { local IFS="$1"; shift; echo "$*"; }

if [ -z "$DISCOVERY_SERVICE" ]; then
  cluster_join=$CLUSTER_JOIN
else
  echo
  echo '>> Registering in the discovery service'

  etcd_hosts=$(echo $DISCOVERY_SERVICE | tr ',' ' ')
  flag=1

  echo
  # Loop to find a healthy etcd host
  for i in $etcd_hosts
  do
    echo ">> Connecting to http://${i}/health"
    curl -s http://${i}/health || continue
    if curl -s http://$i/health | jq -e 'contains({ "health": "true"})'; then
      healthy_etcd=$i
      flag=0
      break
    else
      echo ">> Node $i is unhealthy. Proceed to the next node."
    fi
  done

  # Flag is 0 if there is a healthy etcd host
  if [ $flag -ne 0 ]; then
    echo ">> Couldn't reach healthy etcd nodes."
    exit 1
  fi

  echo
  echo ">> Selected healthy etcd: $healthy_etcd"

  if [ ! -z "$healthy_etcd" ]; then
    URL="http://$healthy_etcd/v2/keys/galera/$CLUSTER_NAME"

    set +e
    echo "`date +%T` >> Waiting for $TTL to read non-expired keys.."
    sleep $TTL

    # Read the list of registered IP addresses
    echo "`date +%T` >> Retrieving list of keys for $CLUSTER_NAME"
    addr=$(curl -s $URL | jq -r '.node.nodes[]?.key' | awk -F'/' '{print $(NF)}')
    cluster_join=$(join , $addr)

    ipaddr=$(hostname -i | awk {'print $1'})
    [ -z $ipaddr ] && ipaddr=$(hostname -I | awk {'print $1'})

    echo
    if [ -z $cluster_join ]; then
      echo "`date +%T` >> KV store is empty. This is the first node to come up."
      echo
      echo "`date +%T` >> Registering $ipaddr in http://$healthy_etcd"
      curl -s $URL/$ipaddr/ipaddress -X PUT -d "value=$ipaddr" -d ttl=$(($TTL * 3))
    else
      curl -s ${URL}?recursive=true\&sorted=true > /tmp/out
      running_nodes=$(cat /tmp/out | jq -r '.node.nodes[].nodes[]? | select(.key | contains ("wsrep_local_state_comment")) | select(.value == "Synced") | .key' | awk -F'/' '{print $(NF-1)}' | tr "\n" ' '| sed -e 's/[[:space:]]*$//')
      echo 
      echo "`date +%T` >> Running nodes: [${running_nodes}]"

      if [ -z "$running_nodes" ]; then
        # if there is no Synced node, determine the sequence number.
        TMP=/var/lib/mysql/$(hostname).err
        echo "`date +%T` >> There is no node in synced state."
        echo " >> It's unsafe to bootstrap unless the sequence number is the latest."
        echo " >> Determining the Galera last committed seqno using --wsrep-recover.."
        echo

        mysqld_safe --wsrep-cluster-address=gcomm:// --wsrep-recover --skip-syslog
        cat $TMP
        seqno=$(grep -o '[a-z0-9]*-[a-z0-9]*:-*[0-9]' $TMP | head -1 | cut -d ":" -f 2)
        # if this is a new container, set seqno to 0
        if [ $INITIALIZED -eq 1 ]; then
          echo ">> This is a new container, thus setting seqno to 0."
          seqno=0
        fi

        echo
        if [ ! -z $seqno ]; then
          echo "`date +%T` >> Reporting seqno:$seqno to ${healthy_etcd}."
          WAIT=$(($TTL * 2))
          curl -s $URL/$ipaddr/seqno -X PUT -d "value=$seqno&ttl=$WAIT"
        else
          echo ">> Bailing, unable to determine Galera sequence number."
	  sleep 60
          exit 1
        fi
        rm $TMP

        echo
        echo "`date +%T` >> Sleeping for $TTL seconds to wait for other nodes to report."
        sleep $TTL

        echo
        echo  "`date +%T` >> Retrieving list of seqno for $CLUSTER_NAME"
        bootstrap_flag=1

        # Retrieve seqno from etcd
        curl -s ${URL}?recursive=true\&sorted=true > /tmp/out
        cluster_seqno=$(cat /tmp/out | jq -r '.node.nodes[].nodes[]? | select(.key | contains ("seqno")) | .value' | tr "\n" ' '| sed -e 's/[[:space:]]*$//')

        for i in $cluster_seqno; do
          if [ $i -gt $seqno ]; then
            bootstrap_flag=0
            echo  "`date +%T` >> Found another node holding a greater seqno ($i/$seqno)"
          fi
        done

        echo
        if [ $bootstrap_flag -eq 1 ]; then
          # Find the earliest node to report if there is no higher seqno
          node_to_bootstrap=$(cat /tmp/out | jq -c '.node.nodes[].nodes[]?' | grep seqno | tr ',:\"' ' ' | sort -k 11 | head -1 | awk -F'/' '{print $(NF-1)}')
          if [ "$node_to_bootstrap" == "$ipaddr" ]; then
            echo  "`date +%T` >> This node is safe to bootstrap."
            cluster_join=
          else
            echo  ">> Based on timestamp, $node_to_bootstrap is the chosen node to bootstrap."
            echo  ">> Wait again for $TTL seconds to look for a bootstrapped node."
            sleep $TTL
            curl -s ${URL}?recursive=true\&sorted=true > /tmp/out

            # Look for a synced node again
            running_nodes2=$(cat /tmp/out | jq -r '.node.nodes[].nodes[]? | select(.key | contains ("wsrep_local_state_comment")) | select(.value == "Synced") | .key' | awk -F'/' '{print $(NF-1)}' | tr "\n" ' '| sed -e 's/[[:space:]]*$//')

            echo
            echo ">> Running nodes: [${running_nodes2}]"

            if [ ! -z "$running_nodes2" ]; then
              cluster_join=$(join , $running_nodes2)
            else
              echo
              echo  ">> Bailing, unable to find a bootstrapped node to join."
	      sleep 60
              exit 1
            fi
          fi
        else
          echo  ">> Refusing to start for now because there is a node holding higher seqno."
          echo  ">> Wait again for $TTL seconds to look for a bootstrapped node."
          sleep $TTL

          # Look for a synced node again
          curl -s ${URL}?recursive=true\&sorted=true > /tmp/out
          running_nodes3=$(cat /tmp/out | jq -r '.node.nodes[].nodes[]? | select(.key | contains ("wsrep_local_state_comment")) | select(.value == "Synced") | .key' | awk -F'/' '{print $(NF-1)}' | tr "\n" ' '| sed -e 's/[[:space:]]*$//')

          echo
          echo ">> Running nodes: [${running_nodes3}]"

          if [ ! -z "$running_nodes2" ]; then
            cluster_join=$(join , $running_nodes3)
          else
            echo
            echo  ">> Bailing, unable to find a bootstrapped node to join."
	    sleep 60
            exit 1
          fi
        fi
      else
        # if there is a Synced node, join the address
        cluster_join=$(join , $running_nodes)
      fi
    fi
    set -e

    echo
    echo ">> Cluster address is gcomm://$cluster_join"
  else
    echo
    echo '>> Bailing, no healthy etcd host detected. Refused to start.'
    exit 1
  fi
fi

echo
echo ">> Starting reporting script in the background"
nohup report_status.sh root $CLUSTER_NAME $TTL $DISCOVERY_SERVICE &

# set IP address based on the primary interface
sed -i "s|WSREP_NODE_ADDRESS|$ipaddr|g" /etc/mysql/my.cnf

echo
echo ">> Starting mysqld process"
if [ -z $cluster_join ]; then
  export _WSREP_NEW_CLUSTER='--wsrep-new-cluster'
  # set safe_to_bootstrap = 1
  GRASTATE=$DATADIR/grastate.dat
  [ -f $GRASTATE ] && sed -i "s|safe_to_bootstrap.*|safe_to_bootstrap: 1|g" $GRASTATE
else
  export _WSREP_NEW_CLUSTER=''
fi

exec mysqld --wsrep_cluster_name=$CLUSTER_NAME --wsrep-cluster-address="gcomm://$cluster_join" --wsrep_sst_auth="xtrabackup:$XTRABACKUP_PASSWORD" $_WSREP_NEW_CLUSTER $CMDARG
