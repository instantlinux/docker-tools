FROM alpine:3.9
MAINTAINER Rich Braun "docker@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=Apache-2.0 \
    org.label-schema.name=vsftpd \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ARG VSFTPD_VERSION=3.0.3-r6
ENV ANONYMOUS_ENABLE=YES \
    ANON_MKDIR_WRITE_ENABLE=NO \
    ANON_UPLOAD_ENABLE=NO \
    FTPUSER_PASSWORD_SECRET=ftp-user-password-secret \
    FTPUSER_NAME=ftpuser \
    FTPUSER_UID=1001 \
    LOCAL_UMASK=022 \
    LOG_FTP_PROTOCOL=NO \
    PASV_ADDRESS= \
    PASV_MAX_PORT=30100 \
    PASV_MIN_PORT=30091 \
    TZ=UTC \
    USE_LOCALTIME=YES \
    VSFTPD_LOG_FILE=/dev/stdout \
    WRITE_ENABLE=YES

RUN apk add --update --no-cache tzdata vsftpd=$VSFTPD_VERSION

VOLUME /etc/vsftpd.d /var/lib/ftp
EXPOSE 21 $PASV_MIN_PORT-$PASV_MAX_PORT

COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
