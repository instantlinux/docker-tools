FROM alpine:3.23
ARG BUILD_DATE
ARG VCS_REF
LABEL org.opencontainers.image.authors="Rich Braun docker@instantlinux.net" \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=GPL-3.0 \
    org.label-schema.name=weewx \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV AIRLINK_HOST= \
    ALTITUDE="100, foot" \
    LATITUDE=50.00 \
    LONGITUDE=-80.00 \
    COMPUTER_TYPE="unbranded PC" \
    DB_BINDING_SUFFIX=mysql \
    DB_DRIVER=weedb.mysql \
    DB_HOST=db \
    DB_NAME=weewx_a \
    DB_NAME_FORECAST=weewx_f \
    DB_USER=weewx \
    DEBUG=0 \
    DEVICE_PORT=/dev/ttyUSB0 \
    HTML_ROOT=/var/www/weewx \
    LOCATION="Anytown, USA" \
    LOGGING_INTERVAL=300 \
    OPERATOR="Al Roker" \
    OPTIONAL_ACCESSORIES=False \
    RAIN_YEAR_START=7 \
    RAPIDFIRE=True \
    RSYNC_HOST=web01 \
    RSYNC_PORT=22 \
    RSYNC_DEST=/usr/share/nginx/html \
    RSYNC_USER=wx \
    SKIN=Standard \
    STATION_FEATURES="fan-aspirated shield" \
    STATION_ID=unset \
    STATION_MODEL=6152 \
    STATION_TYPE=Vantage \
    STATION_URL= \
    SYSLOG_DEST=/var/log/messages \
    TZ=US/Eastern \
    TZ_CODE=10 \
    WEBCAM_URL=https://www.wunderground.com/wundermap?lat=37.761&lon=-122.435&zoom=5&radar=1&cam=1 \
    WEEK_START=6 \
    WX_ROOT=/home/weewx/weewx-data \
    WX_USER=weewx

ARG WEEWX_VERSION=5.2.0
ARG WEEGREEN_VERSION=v0.12
ARG AIRLINK_VERSION=1.4
ARG WX_GROUP=dialout
ARG WX_UID=2071
ARG AIRLINK_SHA=6392ee1d8e96a543306f16430ec9095b79dd7d0aacf8078171aa61b060a49745

COPY install-input.txt entrypoint.sh log.conf /tmp
RUN apk add --no-cache --update \
      curl freetype libjpeg libstdc++ openssh openssl python3 py3-cheetah \
      py3-configobj py3-mysqlclient py3-pillow py3-pymysql py3-pyserial \
      py3-requests py3-six py3-usb rsync rsyslog tzdata && \
    adduser -u $WX_UID -s /bin/sh -G $WX_GROUP -D $WX_USER && \
    mv /tmp/* /home/$WX_USER && \
    apk add --no-cache --virtual .fetch-deps gcc git musl-dev python3-dev && \
    VENV=/home/$WX_USER/weewx-venv && \
    python3 -m venv $VENV --system-site-packages && \
    source $VENV/bin/activate && \
    python3 -m pip install weewx==$WEEWX_VERSION && \
    git clone -b $WEEGREEN_VERSION --depth 1 \
      https://github.com/instantlinux/weewx-WeeGreen.git \
      $WX_ROOT/skins/WeeGreen && \
    chown $WX_USER $WX_ROOT && \
    chown -R $WX_USER $WX_ROOT/skins && \
    su $WX_USER -c \
      "$VENV/bin/weectl station create < /home/$WX_USER/install-input.txt" && \
    cat /home/$WX_USER/log.conf >> $WX_ROOT/weewx.conf && \
    curl -sLo /tmp/weewx-airlink.zip \
      https://github.com/chaunceygardiner/weewx-airlink/releases/download/v$AIRLINK_VERSION/weewx-airlink-$AIRLINK_VERSION.zip && \
    echo "$AIRLINK_SHA  /tmp/weewx-airlink.zip" >> /tmp/checksums && \
      sha256sum -c /tmp/checksums && \
    su $WX_USER -c \
      "$VENV/bin/weectl extension install /tmp/weewx-airlink.zip --yes" && \
    apk del .fetch-deps && \
    rm -fr $WX_ROOT/skins/WeeGreen/.git /home/$WX_USER/.cache && \
    find /usr/lib/python3* $VENV -name __pycache__ -exec rm -r '{}' +;

ENTRYPOINT ["/home/weewx/entrypoint.sh"]
