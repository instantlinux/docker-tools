FROM alpine:3.6
MAINTAINER Rich Braun "docker@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=Apache-2.0 \
    org.label-schema.name=swarm-sync \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV SYNC_ROLE=primary \
    SYNC_SSHKEY= \
    SYNC_INTERVAL=5 \
    SECRET=swarm-sync_sshkey

RUN apk add --update dcron openssh-client openssh-server unison && \
    rm -fr /var/log/* /var/cache/apk/* && \
    mkdir /var/log/unison /root/.unison
USER root
EXPOSE 22

COPY src/ /root/src/
VOLUME ["/var/swarm-sync", "/root/.unison", "/var/log/unison"]
ENTRYPOINT ["/root/src/entrypoint.sh"]
