FROM alpine:3.7

MAINTAINER Rich Braun "docker@instantlinux.net"

ENV ATTACHMENT_DIR=/var/local/squirrelmail/attach/ \
    BANNER_HEIGHT=326 \
    BANNER_IMG=CambridgeBanner.jpg \
    BANNER_WIDTH=433 \
    DATA_DIR=/var/local/squirrelmail/data/ \
    DB_HOST=db00 \
    DB_NAME=squirrelmail \
    DB_NAME_ADDR=contacts \
    DB_PASSWD_SECRET=squirrelmail-db-password \
    DB_USER=sqmail \
    DOMAIN=domain.com \
    IMAP_AUTH_MECH=login \
    IMAP_PORT=993 \
    IMAP_SERVER=imap \
    IMAP_TLS=true \
    MESSAGE_MOTD="Remote WebMail Access" \
    ORGANIZATION="The IT Crowd" \
    PHP_POST_MAX_SIZE=40M \
    PHP_UPLOAD_MAX_FILESIZE=32M \
    PROVIDER_NAME="(Tech Support)" \
    PROVIDER_URI=http://squirrelmail.org \
    SMTP_AUTH_MECH=plain \
    SMTP_PORT=587 \
    SMTP_SMARTHOST=smtp \
    SMTP_TLS=false \
    TZ=UTC

ARG APACHE_UID=48
ARG VERSION=master
ARG GIT_SSL_NO_VERIFY=true

COPY fixes.diff /tmp/
RUN adduser -u $APACHE_UID -s /sbin/nologin -g "Apache" -D apache && \
    apk add --no-cache --update apache2 ca-certificates openssl php5 \
      php5-apache2 php5-mysql php5-openssl php5-pear && \
    mkdir /var/www/localhost/htdocs/squirrelmail && \
    apk add --no-cache --virtual .fetch-deps git && \
    git clone -b $VERSION --depth 1 \
      https://git.instantlinux.net/richb/squirrelmail.git \
      /var/www/localhost/htdocs/squirrelmail && \
    cd /var/www/localhost/htdocs/squirrelmail && \
    patch -p0 < /tmp/fixes.diff && \
    ln -s php5 /usr/bin/php && pear install DB && \
    apk del .fetch-deps && \
    rm -fr /var/cache/apk/* /tmp/* \
      /var/www/localhost/htdocs/squirrelmail/.git

VOLUME /var/log/apache2 /var/local/squirrelmail/attach \
    /var/local/squirrelmail/data
COPY entrypoint.sh /usr/local/bin
ENTRYPOINT /usr/local/bin/entrypoint.sh
