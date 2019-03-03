FROM alpine:3.9
MAINTAINER Rich Braun "docker@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=Apache-2.0 \
    org.label-schema.name=swarm-sync \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV PEERNAME=peer \
    SYNC_ROLE=primary \
    SYNC_SSHKEY= \
    SYNC_INTERVAL=5 \
    SECRET=swarm-sync_sshkey

ARG UNISON_VERSION=2.48.15_p4-r0

RUN apk add --update --no-cache dcron openssh-client openssh-server \
      unison=$UNISON_VERSION && \
    rm -fr /var/log/* /var/cache/apk/* && \
    mkdir /var/log/unison /root/.unison

EXPOSE 22
COPY src/ /root/src/
VOLUME /etc/ssh /root/.unison /var/swarm-sync /var/log/unison
ENTRYPOINT ["/root/src/entrypoint.sh"]
