FROM opensuse:42.3
MAINTAINER Rich Braun "docker@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=Apache-2.0 \
    org.label-schema.name=mythsuse \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV APACHE_LOG_DIR=/var/log/apache2 \
    DBNAME=mythtv \
    DBSERVER=db00 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    TZ=UTC

ARG MYTHTV_UID=2021
ARG MYTHTV_GID=100

RUN \
  zypper --gpg-auto-import-keys ar -f \
    http://packman.inode.at/suse/openSUSE_Leap_42.3/ packman && \
  zypper --gpg-auto-import-keys ref -s && \
  zypper --non-interactive update && \
  zypper --non-interactive in wget less net-tools w3m lynx curl which vim \
    apache2 php5 mariadb-client perl-XML-Twig glibc-locale glibc-i18ndata \
    psmisc xauth openssh xterm \
    mythtv-backend mythweb python-mythtv python-xml php-mythtv mythtv-setup && \
  zypper clean && \
    rm -rf /tmp/* /var/log/* /var/cache/zypp \
    /usr/share/man /usr/share/info /var/cache/man

COPY src/ /root/
RUN \
  echo "Listen 6760" >>/etc/apache2/listen.conf && \
  mv /root/000-default-myth.conf /etc/apache2/vhosts.d/000-default-myth.conf && \
  mv /root/mythweb.conf /etc/apache2/vhosts.d/mythweb.conf && \
  usermod -u $MYTHTV_UID mythtv && \
  usermod -g $MYTHTV_GID mythtv && \
  mkdir -p /home/mythtv/.mythtv /var/lib/mythtv /root/.mythtv \
    $APACHE_LOG_DIR && \
  echo "mythtv:mythtv" | chpasswd && \
  usermod -s /bin/bash -d /home/mythtv mythtv && \
  chown $MYTHTV_UID:$MYTHTV_GID /var/lib/mythtv

EXPOSE 22 3389 5000/udp 5002/udp 5004/udp 6543 6544 6760 65001 65001/udp 
VOLUME $APACHE_LOG_DIR
ENTRYPOINT ["/root/entrypoint.sh"]
