FROM alpine:3.9
MAINTAINER Rich Braun "docker@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=GPL-3.0 \
    org.label-schema.name=weewx \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV ALTITUDE="100, foot" \
    LATITUDE=50.00 \
    LONGITUDE=-80.00 \
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
    RAIN_YEAR_START=7 \
    RAPIDFIRE=True \
    RSYNC_HOST=web01 \
    RSYNC_PORT=22 \
    RSYNC_DEST=/usr/share/nginx/html \
    RSYNC_USER=wx \
    SKIN=Standard \
    STATION_ID=unset \
    STATION_TYPE=Vantage \
    SYSLOG_DEST=/var/log/messages \
    TZ=US/Eastern \
    TZ_CODE=10 \
    WEEK_START=6 \
    WX_USER=weewx \
    XTIDE_LOCATION=unset

ARG PYTHON_PIP_VERSION=19.0.3
ARG FORECAST_VERSION=3.3.2
ARG GETPIP_URI=https://bootstrap.pypa.io/3.3/get-pip.py
ARG HARMONICS_VERSION=20161231
ARG LIBTCD_VERSION=2.2.7-r2
ARG WEEWX_VERSION=3.9.1
ARG XTIDE_VERSION=2.15.1
ARG FORECAST_SHA=8e063e8c2c47d2232c84d5c0b2891a67e4634b2a4f17c7867f482e6db3310d53
ARG GETPIP_SHA=dc84268cc3271fc05d0638dc8a50e49a1450c73abbf67cb12ff1dc1e1a9b3a66
ARG HARMONICS_SHA=7e5da40c19fd4f5d0897d6a7f68bc4b66a3eb7c3852135c8a6c4c56b82c01cdd
ARG LIBTCD_SHA=aff1f218b84106c572d094912cd11c828e1ea212db5661cdcc0e2e6253020a94
ARG WEEWX_SHA=b56a0926f6c0f522a3707eeb90912e0a5e21bc0a97c017289416c7846d6c19dc
ARG WX_GROUP=dialout
ARG WX_UID=2071
ARG XTIDE_SHA=e5c4afbb17269fdde296e853f2cb84845ed1c1bb1932f780047ad71d623bc681

COPY install-input.txt requirements/ /root/

RUN apk add --no-cache --update \
      curl freetype libjpeg libstdc++ openssh openssl python2 py-configobj \
      py-mysqldb rsync rsyslog && \
    adduser -u $WX_UID -s /bin/sh -G $WX_GROUP -D $WX_USER && \
    mkdir -p /usr/share/xtide /build/libtcd /build/xtide && cd build && \
    curl -sLo get-pip.py $GETPIP_URI && \
    curl -sLo harmonics.tar.bz2 \
      ftp://ftp.flaterco.com/xtide/harmonics-dwf-$HARMONICS_VERSION-free.tar.bz2 && \
    curl -sLo libtcd.tar.bz2 \
      ftp://ftp.flaterco.com/xtide/libtcd-$LIBTCD_VERSION.tar.bz2 && \
    curl -sLo weewx.tar.gz \
      http://www.weewx.com/downloads/released_versions/weewx-$WEEWX_VERSION.tar.gz && \
    curl -sLo weewx-forecast.tgz \
      http://lancet.mit.edu/mwall/projects/weather/releases/weewx-forecast-$FORECAST_VERSION.tgz && \
    curl -sLo xtide.tar.bz2 \
      ftp://ftp.flaterco.com/xtide/xtide-$XTIDE_VERSION.tar.bz2 &&\
    echo "$FORECAST_SHA  weewx-forecast.tgz" >> /build/checksums && \
    echo "$HARMONICS_SHA  harmonics.tar.bz2" >> /build/checksums && \
    echo "$GETPIP_SHA  get-pip.py" >> /build/checksums && \
    echo "$LIBTCD_SHA  libtcd.tar.bz2" >> /build/checksums && \
    echo "$WEEWX_SHA  weewx.tar.gz" >> /build/checksums && \
    echo "$XTIDE_SHA  xtide.tar.bz2" >> /build/checksums && \
    sha256sum -c /build/checksums && \
    python get-pip.py --disable-pip-version-check --no-cache-dir \
      pip==$PYTHON_PIP_VERSION && \
    pip --version && \
    apk add --no-cache --virtual .fetch-deps \
      file freetype-dev g++ gawk gcc git jpeg-dev libpng-dev make musl-dev \
      python2-dev zlib-dev && \
    pip install --target /usr/lib/python2.7/site-packages \
      -r /root/amd64.txt && \
    tar xf weewx.tar.gz --strip-components=1 && \
    ./setup.py build && ./setup.py install < /root/install-input.txt && \
    git clone -b master --depth 1 \
      https://github.com/instantlinux/weewx-WeeGreen.git \
      /home/$WX_USER/skins/WeeGreen && \
    /home/$WX_USER/bin/wee_extension --install /build/weewx-forecast.tgz && \
    cd /build/libtcd && \
    tar xf /build/libtcd.tar.bz2 --strip-components=1 && \
    ./configure && make install && \
    cd /build/xtide && \
    tar xf /build/xtide.tar.bz2 --strip-components=1 && \
    ./configure --prefix=/usr && make install && \
    cd /build && tar xf harmonics.tar.bz2 --strip-components=1 && \
    mv harmonics*.tcd /usr/share/xtide/harmonics.tcd && \
    echo /usr/share/xtide > /etc/xtide.conf && \
    apk del .fetch-deps && \
    rm -fr /build /home/$WX_USER/weewx.conf.2* /home/$WX_USER/docs \
      /home/$WX_USER/skins/WeeGreen/.git \
      /root/.cache /var/cache/apk/* /var/log/* && \
    find /home/$WX_USER/bin -name '*.pyc' -exec rm '{}' +;

COPY entrypoint.sh /usr/local/bin
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
