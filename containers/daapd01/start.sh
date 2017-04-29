HOST=`basename \`pwd\``
DOMAIN=ci.net

docker run --detach --restart always --name $HOST \
    --network host \
    --hostname $HOST.$DOMAIN \
    --publish 3689:3689 \
    --env SERVER_BANNER="%h Firefly MP3 via Docker" \
    --volume /pc/MP3:/srv/music:ro \
    --volume daapd-cache:/var/cache/forked-daapd \
    dockerhub.instantlinux.net:5000/mt-daapd:latest
