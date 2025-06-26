FROM alpine:3.22
ARG BUILD_DATE
ARG VCS_REF
LABEL org.opencontainers.image.authors="Rich Braun docker@instantlinux.net" \
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

ARG UNISON_VERSION=2.53.7
ARG OCAML_VERSION=4.14.2-r1
ARG UNISON_SHA=a259537cef465c4806d6c1638c382620db2dd395ae42a0dd2efa3ba92712bed5
ARG RRSYNC_SHA=b745a37909fc10087cc9c901ad7dfda8ad8b6b493097b156b68ba33db4a5a52f

COPY src/ /root/src/
RUN apk add --update openssh-client openssh-server perl rsync && \
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
    make && cp src/unison src/unison-fsmonitor /usr/bin && \
    cd .. && apk del .fetch-deps && \
    rm -fr /build /var/log/* /var/cache/apk/* && \
    mkdir /var/log/unison /root/.unison

EXPOSE 22
VOLUME /etc/ssh /etc/unison.d /root/.unison /var/data-sync /var/log/unison
ENTRYPOINT ["/root/src/entrypoint.sh"]
