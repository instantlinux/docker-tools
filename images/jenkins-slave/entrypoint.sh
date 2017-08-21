#!/bin/bash

set -o errexit

if [ ! -f /etc/timezone ] && [ ! -z "$TZ" ]; then
  # At first startup, set timezone
  cp /usr/share/zoneinfo/$TZ /etc/localtime
  echo $TZ >/etc/timezone
fi

if [ -e /run/secrets/$SWARM_JENKINS_SECRET ]; then
  SWARM_JENKINS_PASSWORD=`cat /run/secrets/$SWARM_JENKINS_SECRET`
fi

[ -n "$SWARM_DELAYED_START" ] && sleep $SWARM_DELAYED_START
[ -n "$SWARM_ENV_FILE" ] && source $SWARM_ENV_FILE

jenkins_user=""
swarm_client_labels=""
swarm_node_name=""

if [ -n "$SWARM_JENKINS_USER" ] && [ -n "$SWARM_JENKINS_PASSWORD" ]; then
  jenkins_user="-username $SWARM_JENKINS_USER -password $SWARM_JENKINS_PASSWORD"
fi

if [ -n "$SWARM_CLIENT_LABELS" ]; then
  swarm_client_labels="-labels $SWARM_CLIENT_LABELS"
fi

if [ -n "$SWARM_CLIENT_NAME" ]; then
  swarm_node_name="-name '$SWARM_CLIENT_NAME'"
fi

unset SWARM_JENKINS_USER
unset SWARM_JENKINS_PASSWORD

if [ "$1" == 'swarm' ]; then
  # Run the Swarm-Client according to environment variables.
    exec $SWARM_JAVA_HOME/bin/java $SWARM_VM_PARAMETERS \
    -jar $SWARM_CLIENT_JAR $SWARM_CLIENT_PARAMETERS  \
    -executors $SWARM_CLIENT_EXECUTORS -fsroot $SWARM_WORKDIR \
    -master $SWARM_MASTER_URL \
    $jenkins_user $swarm_client_labels $swarm_node_name
elif [ "$1" == '-'* ]; then
  # Run the Swarm-Client with passed parameters.
  exec $SWARM_JAVA_HOME/bin/java $JAVA_OPTS \
    -jar $SWARM_CLIENT_JAR "$@"
else
  exec "$@"
fi
