FROM alpine:3.19
MAINTAINER Rich Braun "docker@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=Apache-2.0 \
    org.label-schema.name=nagiosql \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV APACHE_BIN=httpd \
    APACHE_USER=apache \
    DB_HOST=db00 \
    DB_NAME=nagiosql \
    DB_PASSWD_SECRET=nagiosql-db-password \
    DB_PORT=3306 \
    DB_USER=nagiosql \
    NAGIOS_ETC=/opt/nagios/etc \
    TZ=UTC

ARG APACHE_UID=33
ARG NAGIOS_GID=1000
ARG NAGIOS_UID=999
ARG NAGIOS_VERSION=4.4.13-r1
ARG NAGIOSQL_VERSION=3.5.0
ARG NAGIOSQL_SHA=f777dfd8152768669ac73d96a6547fc5d8add80f50fb9fb4e255fc4f344d1222
ARG NAGIOSQL_DOWNLOAD=nagiosql-$NAGIOSQL_VERSION-git2023-06-18.tar.bz2

COPY src /tmp/
COPY html /var/www/html
RUN deluser xfs && addgroup -g $NAGIOS_GID nagios && \
    adduser -u $APACHE_UID -g Apache -DSH -h /var/www apache && \
    adduser -u $NAGIOS_UID -g "Nagios Server" -DSH -h /var/nagios nagios && \
    apk add --update --no-cache apache2 curl nagios=$NAGIOS_VERSION php81 \
      php81-apache2 php81-ftp php81-gettext php81-mysqli php81-pear php81-session \
      php81-pecl-ssh2 tzdata && \
    addgroup apache nagios && \
    echo 'date.timezone = UTC' > /etc/php81/conf.d/50-tz.ini && \
    echo 'include_path = ".:/var/www/nagiosql/libraries/pear"' \
      > /etc/php81/conf.d/50-include.ini && \
    cd /tmp && \
    curl -sLo $NAGIOSQL_DOWNLOAD \
      https://sourceforge.net/projects/nagiosql/files/nagiosql/NagiosQL%20${NAGIOSQL_VERSION}/${NAGIOSQL_DOWNLOAD} && \
    echo "$NAGIOSQL_SHA  $NAGIOSQL_DOWNLOAD" | sha256sum -c && \
    mkdir /var/www/nagiosql && \
    tar xjf $NAGIOSQL_DOWNLOAD -C /var/www/nagiosql --strip-components=1 && \
    mv /tmp/nagiosql.conf /etc/apache2/conf.d/ && \
    mv /tmp/settings.php.j2 /var/www/nagiosql/config/ && \
    chmod a+rX /var/www/html && \
    rm /tmp/*

EXPOSE 80

COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
