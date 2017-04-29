#!/bin/bash
HOST=`basename \`pwd\``
DOMAIN=ci.net
ADV=node3

docker run --detach --restart always --name $HOST \
    --network host \
    --hostname $HOST.$DOMAIN \
    -v etcd_data:/data \
    -p 2379:2379 \
    -p 2380:2380 \
    -p 4001:4001 \
    -p 7001:7001 \
    elcolio/etcd:latest \
    -name $HOST \
    -advertise-client-urls http://$ADV:2379,http://$ADV:4001 \
    -listen-client-urls http://0.0.0.0:2379,http://0.0.0.0:4001 \
    -initial-advertise-peer-urls http://$ADV:2380 \
    -listen-peer-urls http://0.0.0.0:2380 \
    -initial-cluster-token etcd-cluster-1 \
    -initial-cluster etcd00=http://node1:2380,etcd01=http://node2:2380,etcd02=http://node3:2380 \
    -initial-cluster-state new
