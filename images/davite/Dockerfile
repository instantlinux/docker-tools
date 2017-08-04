FROM httpd:2.4.25-alpine
MAINTAINER Rich Braun "docker@instantlinux.net"

ENV TZ=US/Pacific \
    HOSTNAME=davite.example.com \
    SCHEME=http \
    SMTP_SMARTHOST=smtp \
    SMTP_PORT=587 \
    TCP_PORT=:8080 \
    URL_PATH=/davite

RUN apk add --no-cache --update perl && \
    mkdir /usr/local/apache2/htdocs/davite

COPY src/ /usr/local/apache2/htdocs/davite/
COPY src/DaVite.cgi /usr/local/apache2/cgi-bin/DaVite.cgi
COPY entrypoint.sh /usr/local/bin

VOLUME /var/adm/DaVite_Data

ENTRYPOINT /usr/local/bin/entrypoint.sh