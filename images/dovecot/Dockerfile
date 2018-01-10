FROM instantlinux/postfix:17.12
MAINTAINER Rich Braun "docker@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=Apache-2.0 \
    org.label-schema.name=dovecot \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV LDAP_PASSWD_SECRET=ldap-ro-password

RUN apk add --no-cache dovecot dovecot-ldap procmail
EXPOSE 143 993 
VOLUME /etc/dovecot/conf.local /home /var/spool/mail

COPY entrypoint-dovecot.sh /root
ENTRYPOINT /root/entrypoint-dovecot.sh
