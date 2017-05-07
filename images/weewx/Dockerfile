FROM alpine:3.5
MAINTAINER Rich Braun "richb@instantlinux.net"

ENV ALTITUDE="100, foot" \
    LATITUDE=50.00 \
    LONGITUDE=-80.00 \
    DB_BINDING_SUFFIX=mysql \
    DB_DRIVER=weedb.mysql \
    DB_HOST=db \
    DB_NAME=weewx_a \
    DB_NAME_FORECAST=weewx_f \
    DB_USER=weewx \
    HTML_ROOT=/var/www/weewx \
    LOCATION="Anytown, USA" \
    LOGGING_INTERVAL=300 \
    RAIN_YEAR_START=7 \
    RAPIDFIRE=True \
    RSYNC_HOST=web01 \
    RSYNC_DEST=/var/www/htdocs/wx \
    RSYNC_USER=wx \
    SKIN=standard \
    STATION_ID=unset \
    SYSLOG_DEST=/var/log/messages \
    TZ=US/Eastern \
    TZ_CODE=10 \
    WEEK_START=6 \
    XTIDE_LOCATION=unset

ARG PYTHON_PIP_VERSION=9.0.1
ARG WEEWX_VERSION=3.0.1
ARG FORECAST_VERSION=3.0.2

ADD install-input.txt requirements/ /root/

RUN apk add --no-cache --update \
     curl freetype libjpeg openssh openssl python2 python2-dev \
     py-configobj py-mysqldb rsync rsyslog && \
    mkdir build && cd build && \
    wget -q -O get-pip.py https://bootstrap.pypa.io/get-pip.py && \
    wget -q -O weewx.tar.gz \
     http://www.weewx.com/downloads/released_versions/weewx-$WEEWX_VERSION.tar.gz && \
    wget -q -O weewx-forecast.tgz \
     http://lancet.mit.edu/mwall/projects/weather/releases/weewx-forecast-$FORECAST_VERSION.tgz && \
    python get-pip.py --disable-pip-version-check --no-cache-dir \
      pip==$PYTHON_PIP_VERSION && \
    pip --version && \
    apk add --no-cache --virtual .fetch-deps \
      gcc git freetype-dev jpeg-dev musl-dev zlib-dev && \
    pip install -r /root/common.txt && \
    tar xf weewx.tar.gz --strip-components=1 && \
    ./setup.py build && ./setup.py install < /root/install-input.txt && \
    git clone https://github.com/instantlinux/weewx-WeeGreen.git \
      /home/weewx/skins/WeeGreen && \
    ./setup.py install --extension weewx-forecast.tgz && \
    find /usr/local -depth \( \
        \( -type d -a -name test -o -name tests \) -o \
        \( -type f -a -name '*.pyc' -o -name '*.pyo' \) \
      \) -exec rm -rf '{}' +; \
    apk del .fetch-deps; \
    rm -fr /var/log/* /var/cache/apk/* /home/weewx/weewx.conf.2* /build

ADD entrypoint.sh /root/
ENTRYPOINT /root/entrypoint.sh
