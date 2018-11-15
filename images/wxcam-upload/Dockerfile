FROM instantlinux/proftpd:1.3.6-r6
MAINTAINER Rich Braun "docker@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=Apache-2.0 \
    org.label-schema.name=wxcam-upload \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV ANONYMOUS_DISABLE=on \
    CAMS=cam1 \
    INTERVAL=5 \
    PASV_MAX_PORT=30090 \
    PASV_MIN_PORT=30081 \
    UPLOAD_HOSTNAME=webcam.wunderground.com \
    UPLOAD_PASSWORD_SECRET=wunderground-user-password \
    UPLOAD_PATH=/home/wx/upload \
    UPLOAD_USERNAME=required \
    WXUSER_NAME=wx \
    WXUSER_PASSWORD_SECRET=wxcam-password-hashed \
    WXUSER_UID=2060 \
    TZ=UTC

RUN apk add --update --no-cache bash dcron imagemagick ncftp

VOLUME $UPLOAD_PATH

COPY entrypoint-wx.sh wx_upload.sh /usr/local/bin/
ENTRYPOINT ["/usr/local/bin/entrypoint-wx.sh"]
