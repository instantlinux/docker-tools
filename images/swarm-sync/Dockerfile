FROM alpine:3.6
MAINTAINER Rich Braun "docker@instantlinux.net"

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
