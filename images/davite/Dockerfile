FROM httpd:2.4.38-alpine
MAINTAINER Rich Braun "docker@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=Apache-2.0 \
    org.label-schema.name=davite \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV TZ=UTC \
    HOSTNAME=davite.example.com \
    SCHEME=http \
    SMTP_SMARTHOST=smtp \
    SMTP_PORT=587 \
    TCP_PORT=:8080 \
    URL_PATH=/davite

RUN apk add --no-cache --update perl && \
    mkdir /usr/local/apache2/htdocs/davite

COPY src/ /usr/local/apache2/htdocs/davite/
COPY entrypoint.sh /usr/local/bin
RUN chmod -R g+rX,o+rX /usr/local/apache2/htdocs/davite/ && \
    mv /usr/local/apache2/htdocs/davite/DaVite.cgi \
       /usr/local/apache2/cgi-bin/

VOLUME /var/adm/DaVite_Data

ENTRYPOINT /usr/local/bin/entrypoint.sh
