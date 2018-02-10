FROM mono:5.4.1-slim
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
ARG DUPLICATI_VERSION=2.0.2.15
ARG DUPLICATI_RELEASE=2.0.2.15_experimental_2018-01-03
ARG OVERLAY_VERSION=v1.21.2.2
ARG DUPLICATI_SHA=a906bd79b18fc9e7b33712018aaaea17e4e64cbf657a3c2232577b98828a5423
ARG OVERLAY_SHA=50f67ae51e92eed8679d1a9027c971e809d27e788b3f0322b07fc6e8b9839ec0

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

COPY 10-usermod /etc/cont-init.d/
COPY run /etc/services.d/duplicati/
ENTRYPOINT ["/init"]
