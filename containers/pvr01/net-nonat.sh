#! /bin/bash
#  Connect $HOST container to top-level bridge without NAT

HOST=$1
IP=$2
GATEWAY=$3

NETDEV=$HOST-eth0
BRIDGE=br0
PID=`docker inspect -f '{{ .State.Pid }}' $HOST`

sudo ip link add $NETDEV type veth peer name $HOST-ext
sudo ip link set $HOST-ext up
sudo /sbin/brctl addif $BRIDGE $HOST-ext
sudo ip link  set netns $PID dev $NETDEV
sudo nsenter -t $PID -n ip link set $NETDEV up
sudo nsenter -t $PID -n ip addr add $IP/24 dev $NETDEV
sudo nsenter -t $PID -n ip route del default
sudo nsenter -t $PID -n ip route add default via $GATEWAY dev $NETDEV
