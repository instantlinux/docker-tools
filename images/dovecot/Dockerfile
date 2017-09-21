FROM instantlinux/postfix:17.06
MAINTAINER Rich Braun "docker@instantlinux.net"

ENV LDAP_PASSWD_SECRET=ldap-ro-password

RUN apk add --no-cache dovecot dovecot-ldap procmail
EXPOSE 143 993 
VOLUME /etc/dovecot/conf.local /home /var/spool/mail

COPY entrypoint-dovecot.sh /root
ENTRYPOINT /root/entrypoint-dovecot.sh
