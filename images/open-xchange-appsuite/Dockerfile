FROM debian:stretch-slim
MAINTAINER Rich Braun <docker@instantlinux.net>
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=GPL-2.0 \
    org.label-schema.name=open-xchange-appsuite \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ARG OX_VERSION=7.10.1
ENV DEBIAN_FRONTEND=noninteractive \
    OX_ADMIN_MASTER_LOGIN=oxadminmaster \
    OX_CONFIG_DB_HOST=db00 \
    OX_CONFIG_DB_NAME=oxdata \
    OX_CONFIG_DB_USER=openxchange \
    OX_CONTEXT_ADMIN_LOGIN=oxadmin \
    OX_CONTEXT_ADMIN_EMAIL=admin@domain.com \
    OX_CONTEXT_ID=1 \
    OX_SERVER_NAME=oxserver \
    OX_SERVER_MEMORY=2048

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y apt-transport-https gnupg wget && \
    apt-get clean && rm -fr /var/lib/apt/lists/* /var/log/*

COPY open-xchange.list /etc/apt/sources.list.d/open-xchange.list

RUN sed -i -e "s/{{ VERSION }}/${OX_VERSION}/" \
        /etc/apt/sources.list.d/open-xchange.list && \
    wget -q http://software.open-xchange.com/oxbuildkey.pub -O - \
        | apt-key add - && \
    mkdir -p /usr/share/man/man1 && \
    apt-get update && \
    apt-get install -y \
        hunspell open-xchange \
        open-xchange-admin \
        open-xchange-appsuite \
        open-xchange-appsuite-backend \
        open-xchange-appsuite-help-en-us \
        open-xchange-appsuite-l10n-* \
        open-xchange-appsuite-manifest \
        open-xchange-authentication-database \
        open-xchange-caldav \
        open-xchange-carddav \
        open-xchange-documentconverter-api \
        open-xchange-documents-backend \
        open-xchange-documents-help-en-us \
        open-xchange-documents-ui \
        open-xchange-documents-ui-static \
        open-xchange-grizzly \
        open-xchange-l10n-* \
        open-xchange-passwordchange-database vim && \
    apt-get install -y --allow-unauthenticated oxldapsync && \
    apt-get clean && rm -fr /var/lib/apt/lists/* /var/log/*

COPY proxy_http.conf /etc/apache2/conf-available/proxy_http.conf
COPY open-xchange.conf /etc/apache2/sites-available/open-xchange.conf

RUN a2enmod deflate expires headers lbmethod_byrequests mime proxy \
        proxy_balancer proxy_http rewrite setenvif && \
    a2ensite open-xchange && a2dissite 000-default && \
    a2enconf proxy_http && \
    mkdir -p -m 0777 /ox /ox/store && \
    chown open-xchange:open-xchange /ox/store && \
    echo 'PATH=/opt/open-xchange/sbin:$PATH' >>/root/.bashrc

VOLUME /ox/store /ox/etc /var/log/apache2 /var/log/open-xchange

EXPOSE 80

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT /usr/local/bin/entrypoint.sh
