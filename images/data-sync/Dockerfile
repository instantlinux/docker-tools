FROM alpine:3.8
MAINTAINER Rich Braun "docker@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=Apache-2.0 \
    org.label-schema.name=data-sync \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV PEERNAME= \
    SYNC_SSHKEY= \
    SYNC_INTERVAL=5 \
    SECRET=data-sync-sshkey

ARG UNISON_VERSION=2.48.15_p4-r0

RUN apk add --update --no-cache openssh-client openssh-server \
      unison=$UNISON_VERSION && \
    rm -fr /var/log/* && \
    mkdir /var/log/unison /root/.unison

EXPOSE 22
COPY src/ /root/src/
VOLUME /etc/ssh /etc/unison.d /root/.unison /var/data-sync /var/log/unison
ENTRYPOINT ["/root/src/entrypoint.sh"]
