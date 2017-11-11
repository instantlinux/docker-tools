FROM alpine:3.5
MAINTAINER Rich Braun "docker@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=GPL-2.0 \
    org.label-schema.name=il-v1 \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV DB_HOST=db00 \
    DB_NAME=instantlinux \
    DB_PASSWD_SECRET=il-v1-db-password \
    DB_USER=cakephp \
    FQDN=instantlinux.domain.com \
    REMOTES=host.domain.com \
    SECRET_SSH_CAPI=il_capi_sshkey \
    SECRET_SSH_PROXY=il_proxy_sshkey \
    SECRET_ILCLIENT_PASSWORD=ilclient-password \
    SECRET_ILINUX_PASSWORD=ilinux-password \
    SECRET_MYSQL_BACKUP=mysql-backup \
    TZ=UTC

ARG APACHE_UID=48
ARG CAPI_UID=2016
ARG CARE_GID=505
ARG GIT_SSL_NO_VERIFY=true
ARG LOGS_GID=2001

ARG SCRIPTACULOUS_SHA=1fa39bd110d3326a14f920601803813f088d08ecb2cc645aa7075884d998f6f6
ARG TINYMCE_SHA=282d878139711ebb6752c5ef26681463a4f9805f2d882f2030d9236e20ae56b9

RUN addgroup -g $CARE_GID care && \
    addgroup -g $LOGS_GID logs && \
    adduser -u $APACHE_UID -s /sbin/nologin -g "Apache" -D apache && \
    adduser -u $CAPI_UID -s /bin/sh -g "Capistrano" -G care -D capi && \
    adduser -s /sbin/nologin -g "Memcached" -D memcached && \
    apk add --no-cache --update apache2 bash ca-certificates curl \
      mariadb-client memcached net-tools openssl openssh-client php5 \
      php5-apache2 php5-apcu php5-memcache php5-mysql php5-mysqli php5-openssl \
      php5-pear ruby sudo && \
    mkdir -p -m 755 /var/www/htdocs/il /root/src && \
    pear channel-update pear.php.net && pear install MDB2 && \
    apk add --no-cache --virtual .fetch-deps build-base git ruby-dev && \
    gem install --no-rdoc --no-ri capistrano io-console && \
    git clone -b 1.3.21 --depth 1 https://github.com/cakephp/cakephp.git \
      /var/www/htdocs/il && rm -fr /var/www/htdocs/il/.git && \
    git clone -b 1.3.0 --depth 1 https://github.com/cakephp/debug_kit.git \
      /var/www/htdocs/il/app/plugins/debug_kit && \
    git clone -b master --depth 1 \
      https://git.instantlinux.net/richb/ilwork.git /root/src/ilwork && \
    git clone -b master --depth 1 \
      https://git.instantlinux.net/richb/instantlinux.git /root/src/il && \
    git clone -b master --depth 1 \
      https://git.instantlinux.net/richb/puppet_modules.git /root/src/mod && \
    mv /root/src/mod/modules/capistrano/templates/*.erb /root/src/ && \
    mv /root/src/mod/modules/iltools/templates/*.erb /root/src/ && \
    rm -r /root/src/il/.git /root/src/mod && \
    rm -r /root/src/il/usr/src/squirrelmail-1.4 && \
    rm -fr /var/www/htdocs/il/app/plugins/debug_kit/.git && \
    apk del .fetch-deps && rm -r /var/cache/apk/*

RUN cp -a /root/src/ilwork/usr/src/ilinux/private/modules/cakephp/templates/. \
      /root/src/ && \
    cp -a /root/src/ilwork/usr/src/ilinux/private/frontend \
      /var/www/htdocs/il/ && \
    cp -a /root/src/il/. / && rm -r /root/src/il && \
    cd /tmp && \
    curl -sL https://script.aculo.us/dist/scriptaculous-js-1.9.0.zip \
      -o scriptaculous.zip && \
    curl -sL http://download.moxiecode.com/tinymce/tinymce_3.5.11.zip \
      -o tinymce.zip && \
    echo "$SCRIPTACULOUS_SHA  scriptaculous.zip" > checksums && \
    echo "$TINYMCE_SHA  tinymce.zip" >> checksums && \
    sha256sum -c checksums && \
    unzip -d /var/www/htdocs/il/app/webroot tinymce.zip && \
    unzip scriptaculous.zip scriptaculous-js-1.9.0/src/* && \
    mv scriptaculous-js-1.9.0/src/*.js \
      /var/www/htdocs/il/app/webroot/js/ && \
    mv /usr/lib/ilinux/actions /var/lib/ilinux/ && \
    rm -fr /tmp/* /root/src/ilwork

COPY src/ /root/src/
RUN tar xzf /root/src/cake-from-manifest.tar.gz -C /var/www/htdocs/il/app && \
    tar xzf /root/src/mvc.tar.gz -C /var/www/htdocs/il/app && \
    ln -s frontend /var/www/htdocs/il/svn && \
    mv /root/src/capi-sudo /etc/sudoers.d && \
    chmod 400 /etc/sudoers.d/capi-sudo && \
    rm -r /root/src/*.tar.gz

EXPOSE 80
VOLUME /var/log /var/run/ilinux/arch /var/www/htdocs/il/app/tmp
COPY entrypoint.sh /usr/local/bin
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
