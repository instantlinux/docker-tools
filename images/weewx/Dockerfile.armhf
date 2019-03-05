FROM resin/rpi-raspbian:jessie
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

ARG DEBIAN_FRONTEND=noninteractive
ARG PYTHON_PIP_VERSION=9.0.1
ARG FORECAST_VERSION=3.2.17
ARG WEEWX_VERSION=3.8.0
ARG FORECAST_SHA=dbc7b875ec20c702e44d57d7c8d30666494561dd054f6b96096d8635c39160e9
ARG WEEWX_SHA=9f4e59f3c488f7b7545d6d28cc33d21995e8a21045868433612d45a860ec7d08
ARG WX_GROUP=dialout
ARG WX_UID=2071

COPY install-input.txt requirements/ /root/

RUN apt-get -yq update && apt-get install -yq --no-install-recommends \
      curl libjpeg8 openssh-client python python-configobj python-imaging \
      python-mysqldb rsync rsyslog xtide xtide-data && \
    useradd -u $WX_UID -s /bin/bash -g $WX_GROUP -m $WX_USER && \
    cd /tmp && \
    curl -sLo get-pip.py https://bootstrap.pypa.io/get-pip.py && \
    curl -sLo weewx.tar.gz \
      http://www.weewx.com/downloads/released_versions/weewx-$WEEWX_VERSION.tar.gz && \
    curl -sLo weewx-forecast.tgz \
      http://lancet.mit.edu/mwall/projects/weather/releases/weewx-forecast-$FORECAST_VERSION.tgz && \
    echo "$FORECAST_SHA  weewx-forecast.tgz" > checksums && \
    echo "$WEEWX_SHA  weewx.tar.gz" >> checksums && \
    sha256sum -c checksums && \
    python get-pip.py --disable-pip-version-check --no-cache-dir \
      pip==$PYTHON_PIP_VERSION && \
    pip --version && \
    apt-get install -yq --no-install-recommends \
      libfreetype6-dev gawk gcc git libjpeg8-dev libpng12-dev python-dev && \
    pip install --target /usr/lib/python2.7 \
      -r /root/armhf.txt && \
    pip freeze && cd /tmp && \
    tar xf weewx.tar.gz --strip-components=1 && \
    ./setup.py build && ./setup.py install < /root/install-input.txt && \
    git clone -b master --depth 1 \
      https://github.com/instantlinux/weewx-WeeGreen.git \
      /home/$WX_USER/skins/WeeGreen && \
    /home/$WX_USER/bin/wee_extension --install weewx-forecast.tgz && \
    apt-get purge \
      libfreetype6-dev gawk gcc git libjpeg8-dev libpng12-dev python-dev && \
    rm -fr /tmp/* /home/$WX_USER/weewx.conf.2* /home/$WX_USER/docs \
      /home/$WX_USER/skins/WeeGreen/.git \
      /root/.cache /var/lib/apt/lists/* /var/log/* && \
    find /home/$WX_USER/bin -name '*.pyc' -exec rm '{}' +;

COPY entrypoint.sh /usr/local/bin
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
