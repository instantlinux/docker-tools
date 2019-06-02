# Note: the image is nearly 3x bigger under ubuntu than alpine
# TODO: switch to alpine whenever nagios4 is available for it
FROM ubuntu:16.04
MAINTAINER Rich Braun "docker@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=Apache-2.0 \
    org.label-schema.name=nagiosql \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV APACHE_USER=www-data \
    DB_HOST=db00 \
    DB_NAME=nagiosql \
    DB_PASSWD_SECRET=nagiosql-db-password \
    DB_PORT=3306 \
    DB_USER=nagiosql \
    TZ=UTC

ARG DEBIAN_FRONTEND=noninteractive
ARG NAGIOS_GID=1000
ARG NAGIOS_UID=999
ARG NAGIOSQL_VERSION=3.4.0
ARG NAGIOSQL_SHA=31366dc7f5e6f2e33b060caf18bba233b276d685156a802a2971be230d582106
ARG NAGIOSQL_DOWNLOAD=nagiosql-$NAGIOSQL_VERSION.tar.bz2

COPY src /tmp/
RUN apt-get update && \
    apt-get install -y apache2 bzip2 curl libapache2-mod-php php php-gettext \
      php-mysql php-ssh2 tzdata && apt-get clean
RUN \
    sed -i -e 's/;date.timezone =/date.timezone = UTC/' \
      /etc/php/7.0/apache2/php.ini && \
    cd /tmp && \
    curl -sLo $NAGIOSQL_DOWNLOAD \
      https://sourceforge.net/projects/nagiosql/files/nagiosql/NagiosQL%20${NAGIOSQL_VERSION}/${NAGIOSQL_DOWNLOAD} && \
    echo "$NAGIOSQL_SHA  $NAGIOSQL_DOWNLOAD" | sha256sum -c && \
    mkdir /var/www/nagiosql && \
    tar xjf $NAGIOSQL_DOWNLOAD -C /var/www/nagiosql --strip-components=1 && \
    groupadd -g $NAGIOS_GID nagios && \
    useradd -u $NAGIOS_UID -c Nagios -s /sbin/nologin -g nagios nagios && \
    usermod -G nagios $APACHE_USER && \
    mv /tmp/nagiosql.conf /etc/apache2/conf-enabled/ && \
    mv /tmp/settings.php.j2 /var/www/nagiosql/config/ && \
    rm -fr /tmp/* /var/log/[b-w]*

COPY html /var/www/html
RUN chmod a+rX /var/www/html
EXPOSE 80

VOLUME /opt/nagios/etc /opt/nagios/var
COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
