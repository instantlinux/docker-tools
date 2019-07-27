FROM mono:5.16.0-slim
MAINTAINER Rich Braun "docker@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=GPL-2.1 \
    org.label-schema.name=duplicati \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV PUID=34 \
    TZ=UTC

ARG DEBIAN_FRONTEND=noninteractive
ARG DUPLICATI_VERSION=2.0.4.21
ARG DUPLICATI_RELEASE=2.0.4.21_experimental_2019-06-28
ARG OVERLAY_VERSION=v1.21.8.0
ARG DUPLICATI_SHA=d4f1a2fd4bce850dade73fcba930b59c6cf0199820969c5d300693a841a0cf91
ARG OVERLAY_SHA=383d28edcc47b3b0b21979d022af952f3cf61d1f47fa7911d0825f64efaa82b3

RUN apt-get -yq update && apt-get install -yq bzip2 curl mediainfo mono-devel \
      mono-vbnc sqlite3 unzip && \
    cd /tmp && \
    curl -sLo duplicati.zip \
      https://github.com/duplicati/duplicati/releases/download/v${DUPLICATI_VERSION}-${DUPLICATI_RELEASE}/duplicati-${DUPLICATI_RELEASE}.zip && \
    curl -sLo s6-overlay.tar.gz \
      https://github.com/just-containers/s6-overlay/releases/download/${OVERLAY_VERSION}/s6-overlay-amd64.tar.gz && \
    echo "$DUPLICATI_SHA  duplicati.zip" > checksums && \
    echo "$OVERLAY_SHA  s6-overlay.tar.gz" >> checksums && \
    sha256sum -c checksums && \
    mkdir /app && unzip duplicati.zip -d /app/duplicati && \
    tar xzf s6-overlay.tar.gz -C / && \
    usermod -d /config backup && \
    mkdir /etc/services.d/duplicati && \
    apt-get clean && rm -fr /var/lib/apt/list/* /tmp/*

VOLUME /backups /config /source
EXPOSE 8200

COPY 10-usermod 20-timezone /etc/cont-init.d/
COPY run /etc/services.d/duplicati/
ENTRYPOINT ["/init"]
