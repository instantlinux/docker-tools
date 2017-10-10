FROM alpine:3.6
MAINTAINER Rich Braun "docker@instantlinux.net"

ENV ANONYMOUS_ENABLE=YES \
    ANON_MKDIR_WRITE_ENABLE=NO \
    ANON_UPLOAD_ENABLE=NO \
    FTPUSER_PASSWORD_SECRET=ftp-user-password-secret \
    FTPUSER_NAME=ftpuser \
    FTPUSER_UID=1001 \
    LOCAL_UMASK=022 \
    LOG_FTP_PROTOCOL=NO \
    PASV_MAX_PORT=30100 \
    PASV_MIN_PORT=30091 \
    TZ=UTC \
    USE_LOCALTIME=YES \
    VSFTPD_LOG_FILE=/dev/stdout \
    WRITE_ENABLE=YES

RUN apk add --update --no-cache tzdata vsftpd && \
    passwd -l root

VOLUME /etc/vsftpd.d /var/lib/ftp
EXPOSE 21 $PASV_MIN_PORT-$PASV_MAX_PORT

COPY entrypoint.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
