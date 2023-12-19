FROM alpine:3.19
MAINTAINER Rich Braun "docker@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=GPL-3.0 \
    org.label-schema.name=openldap \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ARG OPENLDAP_VERSION=2.6.6-r1
ENV SLAPD_DN_ATTR=uid \
    SLAPD_FQDN=example.com \
    SLAPD_LOG_LEVEL=Config,Stats \
    SLAPD_ORGANIZATION=Example \
    SLAPD_OU=ou=users, \
    SLAPD_PWD_ATTRIBUTE=userPassword \
    SLAPD_PWD_CHECK_QUALITY=2 \
    SLAPD_PWD_FAILURE_COUNT_INTERVAL=1200 \
    SLAPD_PWD_LOCKOUT_DURATION=1200 \
    SLAPD_PWD_MAX_FAILURE=5 \
    SLAPD_PWD_MIN_LENGTH=8 \
    SLAPD_ROOTDN= \
    SLAPD_ROOTPW_HASH= \
    SLAPD_ROOTPW_SECRET=openldap-ro-password \
    SLAPD_SUFFIX= \
    SLAPD_ULIMIT=2048 \
    SLAPD_USERPW_SECRET=openldap-user-passwords

RUN apk add --update --no-cache gettext gzip openldap=$OPENLDAP_VERSION \
      openldap-clients openldap-back-mdb openldap-passwd-pbkdf2 \
      openldap-overlay-auditlog openldap-overlay-memberof \
      openldap-overlay-ppolicy openldap-overlay-refint
VOLUME /etc/openldap/prepopulate /var/lib/openldap/openldap-data \
      /etc/ssl/openldap
EXPOSE 389 636
COPY slapd.conf /root/
COPY ldif/ /root/ldif/
COPY entrypoint.sh /usr/local/bin/

ENTRYPOINT /usr/local/bin/entrypoint.sh
