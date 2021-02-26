FROM alpine:3.13
MAINTAINER Rich Braun "docker@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=Apache-2.0 \
    org.label-schema.name=data-sync \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV PEERNAME= \
    PUBKEY1= \
    PUBKEY2= \
    RRSYNC_ROOT=/ \
    SYNC_INTERVAL=5 \
    SSHKEY1=data-sync-sshkey1 \
    SSHKEY2=data-sync-sshkey2

ARG UNISON_VERSION=2.51.3
ARG OCAML_VERSION=4.08.1-r5
ARG UNISON_SHA=0c287d17f52729440b2bdc28edf4d19b2d5ea5869983d78e780d501c5866914b
ARG RRSYNC_SHA=b745a37909fc10087cc9c901ad7dfda8ad8b6b493097b156b68ba33db4a5a52f

COPY src/ /root/src/
RUN apk add --update openssh-client openssh-server perl rsync && \
    passwd -u root && \
    cd /usr/local/bin && \
    wget -q https://raw.githubusercontent.com/instantlinux/docker-tools/master/ansible/roles/docker_node/files/rrsync && \
    echo "$RRSYNC_SHA  rrsync" | sha256sum -c && \
    chmod 755 rrsync && chmod g-w,o-w /root/src/* && \
    apk add --no-cache --virtual .fetch-deps bash curl make musl-dev \
      ocaml=$OCAML_VERSION && \
    mkdir /build && cd /build && \
    curl -sLo unison.tar.gz \
      https://github.com/bcpierce00/unison/archive/v$UNISON_VERSION.tar.gz && \
    echo "$UNISON_SHA  unison.tar.gz" | sha256sum -c && \
    tar zxf unison.tar.gz --strip-components=1 && \
    sed -i -e 's/GLIBC_SUPPORT_INOTIFY 0/GLIBC_SUPPORT_INOTIFY 1/' \
      src/fsmonitor/linux/inotify_stubs.c && \
    make && cp src/unison src/unison-fsmonitor /usr/bin && \
    cd .. && apk del .fetch-deps && \
    rm -fr /build /var/log/* /var/cache/apk/* && \
    mkdir /var/log/unison /root/.unison

EXPOSE 22
VOLUME /etc/ssh /etc/unison.d /root/.unison /var/data-sync /var/log/unison
ENTRYPOINT ["/root/src/entrypoint.sh"]
