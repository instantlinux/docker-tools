FROM ubuntu:noble
ARG BUILD_DATE
ARG VCS_REF
LABEL org.opencontainers.image.authors="Rich Braun docker@instantlinux.net" \
    org.label-schema.license=GPL-2.0 \
    org.label-schema.name=mythtv-backend \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV APACHE_LOG_DIR=/var/log/apache2 \
    DBNAME=mythtv \
    DBSERVER=db00 \
    DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    LOCALHOSTNAME= \
    TZ=UTC

ARG APT_SIG=13551B881504888C
ARG MYTHTV_GID=100
ARG MYTHTV_UID=2021
ARG MYTHTV_PPA=http://ppa.launchpad.net/mythbuntu/35
ARG MYTHTV_VERSION=2:35.0+fixes.202512301852.805e05b76a~ubuntu24.04.1
ARG MYTHLINK_SHA=459cb8b60adae4b631a95a9cfb1b41dcb959cc4a0b9053582a711d58b8d8a0d2

RUN \
  apt-get -yq update && \
  apt-get install -yq gnupg locales wget && \
  apt-key adv --recv-keys --keyserver keyserver.ubuntu.com $APT_SIG && \
  echo "deb $MYTHTV_PPA/ubuntu noble main" \
    > /etc/apt/sources.list.d/mythbuntu.list && \
  apt-get -yq update && \
  locale-gen $LANG && \
  echo "# added via Dockerfile\npath-include=/usr/share/doc/mythtv-backend/contrib/*" > \
   /etc/dpkg/dpkg.cfg.d/mythtv-backend && \
  apt-get -yq --no-install-recommends install \
    curl iputils-ping less lsb-release mariadb-client net-tools \
    mythtv-backend=$MYTHTV_VERSION \
    mythtv-common=$MYTHTV_VERSION mythtv-transcode-utils=$MYTHTV_VERSION \
    libmyth-python libmythtv-perl php-mythtv php8.3 psmisc \
    sudo tzdata v4l-utils vim w3m x11-utils xauth xmltv xterm

COPY src/ /root/

RUN \
  usermod -u $MYTHTV_UID -s /bin/bash mythtv && \
  mkdir -p /var/lib/mythtv $APACHE_LOG_DIR && \
  echo "mythtv:mythtv" | chpasswd && \
  chown $MYTHTV_UID:$MYTHTV_GID /var/lib/mythtv && \
  ln -s /usr/share/doc/mythtv-backend/contrib/user_jobs/mythlink.pl /usr/bin

EXPOSE 5000/udp 5002/udp 5004/udp 6543 6544 6549 65001 65001/udp 
VOLUME $APACHE_LOG_DIR
ENTRYPOINT ["/root/entrypoint.sh"]
