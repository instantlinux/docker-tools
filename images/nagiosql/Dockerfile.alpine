FROM php:7.2.10-cli-alpine3.8
MAINTAINER Rich Braun "docker@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=Apache-2.0 \
    org.label-schema.name=nagiosql \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV DB_HOST=db00 \
    DB_NAME=nagiosql \
    DB_PASSWD_SECRET=nagiosql-db-password \
    DB_PORT=3306 \
    DB_USER=nagiosql \
    TZ=UTC

ARG APACHE_UID=33
ARG NAGIOS_GID=1000
ARG NAGIOS_UID=999
ARG NAGIOSQL_VERSION=3.4.0
ARG NAGIOSQL_SHA=b03a8ef59785cf52ec9cce152c49198a7ae2ac14c54120740d53df834156d403
ARG NAGIOSQL_DOWNLOAD=nagiosql-$NAGIOSQL_VERSION.tar.bz2

COPY src /tmp/
RUN deluser xfs && \
    adduser -u $APACHE_UID -s /sbin/nologin -g Apache -D -H -h /var/www apache && \
    apk add --update --no-cache apache2 php7-apache2 php7-ftp php7-gettext \
      php7-mysqli php7-pear php7-session php7-ssh2 tzdata && \
    sed -i -e 's/;date.timezone =/date.timezone = UTC/' /etc/php7/php.ini && \
    cd /tmp && \
    curl -sLo $NAGIOSQL_DOWNLOAD \
      https://sourceforge.net/projects/nagiosql/files/nagiosql/NagiosQL%20${NAGIOSQL_VERSION}/${NAGIOSQL_DOWNLOAD} && \
    echo "$NAGIOSQL_SHA  $NAGIOSQL_DOWNLOAD" | sha256sum -c && \
    mkdir /var/www/nagiosql && \
    tar xjf $NAGIOSQL_DOWNLOAD -C /var/www/nagiosql --strip-components=1 && \
    mv /tmp/nagiosql.conf /etc/apache2/conf.d/ && \
    mv /tmp/settings.php.j2 /var/www/nagiosql/config/ && \
    mv /tmp/html/* /var/www/html/ && \
    rm /tmp/*

EXPOSE 80

COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
