FROM alpine:3.13
MAINTAINER Rich Braun "docker@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=GPL-2.0 \
    org.label-schema.name=nagios \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ARG NAGIOS_VERSION=4.4.6-r1
ARG NAGIOS_GID=1000
ARG NAGIOS_UID=999
ARG PLUGINS_VERSION=2.3.2-r1
ARG WWW_UID=33
ENV AUTHORIZED_USERS=nagiosadmin \
    CONFIG_CHECK=yes \
    HTPASSWD_SECRET=nagios-htpasswd \
    MAIL_AUTH_USER= \
    MAIL_AUTH_SECRET=nagios-mail-secret \
    MAIL_RELAY_HOST=smtp:25 \
    MAIL_USE_TLS=yes \
    NAGIOS_FQDN=nagios.docker \
    NGINX_PORT=80 \
    PERF_ENABLE=yes \
    TZ=UTC

RUN echo '@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing' \
      >>/etc/apk/repositories && \
    deluser xfs && addgroup -g $NAGIOS_GID nagios && \
    adduser -g www-data -u $WWW_UID -DSH -h /var/www www-data && \
    adduser -G nagios -g "Nagios Server" -DSH -h /var/nagios -u $NAGIOS_UID \
      nagios && \
    apk add --update --no-cache nagios=$NAGIOS_VERSION \
      nagios-plugins-all=$PLUGINS_VERSION nagios-web \
      nrpe-plugin bash curl fcgiwrap file mariadb-client nginx openssl \
      perl-crypt-x509 perl-libwww perl-text-glob perl-timedate \
      php7 php7-fpm py3-pip py3-pymysql@testing python3 ssmtp tzdata && \
    addgroup nginx nagios && \
    chmod u+s /usr/lib/nagios/plugins/check_ping && \
    sed -i -e s/use_syslog=.*/use_syslog=0/ \
           -e s/^cfg_file/#cfg_file/ /etc/nagios/nagios.cfg && \
    echo '$USER2$=/opt/nagios/plugins' >> /etc/nagios/resource.cfg && \
    mv /etc/nagios/nagios.cfg /etc/nagios/nagios.cfg.proto && \
    ln -fns /usr/local/bin/mail.sh /usr/sbin/sendmail && \
    ln -s /usr/local/bin/mail.sh /usr/bin/mail && \
    rm /etc/nginx/conf.d/default.conf

EXPOSE 80
VOLUME /etc/nagios /opt/nagios/plugins /var/nagios

COPY nginx.conf /etc/nginx/conf.d/nagios.conf
COPY php-fpm-www.conf /etc/php7/php-fpm.d/www.conf
COPY entrypoint.sh mail.sh /usr/local/bin/
ENTRYPOINT /usr/local/bin/entrypoint.sh
