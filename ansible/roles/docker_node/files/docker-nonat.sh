#! /bin/bash
#  Connect $HOST container to top-level bridge without NAT

HOST=$1
IP=$2
GATEWAY=$3

NETDEV=$HOST-eth0
BRIDGE=br0
PID=`docker inspect -f '{{ .State.Pid }}' $HOST`

ip link del $HOST-ext
ip link add $NETDEV type veth peer name $HOST-ext
ip link set $HOST-ext up
/sbin/brctl addif $BRIDGE $HOST-ext
ip link set netns $PID dev $NETDEV
nsenter -t $PID -n ip link set $NETDEV up
nsenter -t $PID -n ip addr add $IP/24 dev $NETDEV
nsenter -t $PID -n ip route del default
nsenter -t $PID -n ip route add default via $GATEWAY dev $NETDEV
if [ $HOST == 'pvr01' ]; then
  # wait for container to come up
  sleep 6
  docker exec $HOST bash -c 'killall -9 mythbackend ; sleep 2 ; su mythtv -c "/usr/bin/mythbackend --logpath /var/log/mythtv  >/dev/null 2>&1 &"'
fi
iptables -I FORWARD -s $IP -j ACCEPT
iptables -I FORWARD -d $IP -j ACCEPT
