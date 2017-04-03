HOST=`basename \`pwd\``
DOMAIN=instantlinux.net
IP=192.168.2.117

docker run --detach --restart always --name $HOST \
    --hostname $HOST.$DOMAIN \
    --volume /var/dvol/$HOST/etc:/opt/splunk/etc \
    --volume /var/dvol/$HOST/var:/opt/splunk/var \
    --publish $IP:80:8000 \
    --publish $IP:1514:1514 \
    --publish $IP:8088:8088 \
    --publish $IP:8089:8089 \
    --publish $IP:9997:9997 \
    -e "SPLUNK_START_ARGS=--accept-license --answer-yes" \
    -e "SPLUNK_USER=root" \
    -e "SPLUNK_ENABLE_LISTEN=9997" \
    -e "SPLUNK_ADD=tcp 1514" \
    dockerhub.instantlinux.net:5000/splunk:6.5.2
