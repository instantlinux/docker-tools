FROM alpine:3.22
ARG BUILD_DATE
ARG VCS_REF
LABEL org.opencontainers.image.authors="Rich Braun docker@instantlinux.net" \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=GPL-3.0 \
    org.label-schema.name=samba \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ARG SAMBA_VERSION=4.21.4-r4
ENV LOGON_DRIVE=H \
    NETBIOS_NAME=samba \
    SERVER_STRING="Samba Server" \
    TZ=UTC \
    WORKGROUP=WORKGROUP

RUN apk add --update --no-cache samba=$SAMBA_VERSION shadow tzdata

VOLUME /etc/samba/conf.d /var/log/samba
EXPOSE 137-138/udp 139 445

COPY smb.conf.j2 /root/
COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
