FROM mono:5.20.1.34-slim
MAINTAINER Rich Braun "docker@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=LGPL-2.1 \
    org.label-schema.name=duplicati \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV PUID=34 \
    TZ=UTC

ARG DEBIAN_FRONTEND=noninteractive
ARG DUPLICATI_VERSION=2.0.5.0
ARG DUPLICATI_RELEASE=2.0.5.0_experimental_2020-01-03
ARG OVERLAY_VERSION=v1.22.1.0
ARG DUPLICATI_SHA=1982345eda8f77f6f73cc547996c801e5674e54d3524b4bb7ef4752a6dd3d4e6
ARG OVERLAY_SHA=73f9779203310ddf9c5132546a1978e1a2b05990263b92ed2c34c1e258e2df6c

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
