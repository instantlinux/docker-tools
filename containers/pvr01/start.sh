HOST=`basename \`pwd\``
DOMAIN=`hostname -d`
IP=192.168.2.116
GATEWAY=192.168.2.252
DBSERVER=db00
DBNAME=myth28

docker run --detach --restart always --name $HOST \
    --env DISPLAY=$DISPLAY \
    --hostname $HOST.$DOMAIN \
    --env TZ=US/Pacific \
    --env DBSERVER=$DBSERVER \
    --env DBNAME=$DBNAME \
    --volume /var/dvol/$HOST/home:/home/mythtv \
    --volume /var/dvol/$HOST/logs/apache2:/var/log/apache2 \
    --volume /var/dvol/$HOST/logs/mythtv:/var/log/mythtv \
    --volume /var/mythdata:/var/mythdata \
    --volume /var/mythtv:/var/mythtv \
    dockerhub.instantlinux.net:5000/mythsuse:20170322 \
    bash -c 'tail -f /etc/resolv.conf'
#./net-nonat.sh $HOST $IP $GATEWAY

#    --publish $IP:3389:3389 \
#    --publish $IP:6543:6543 \
#    --publish $IP:6544:6544 \
#    --publish $IP:6760:6760 \
#    --publish $IP:65001:65001 \
#    --publish $IP:5000:5000/udp \
#    --publish $IP:5002:5002/udp \
#    --publish $IP:5004:5004/udp \
#    --publish $IP:65001:65001/udp \
