FROM opensuse:latest
MAINTAINER Rich Braun "docker@instantlinux.net"

# Set correct environment variables
ENV \
    APACHE_LOCK_DIR="/var/lock/apache2" \
    APACHE_LOG_DIR="/var/log/apache2" \
    APACHE_PID_FILE="/var/run/apache2.pid" \
    APACHE_RUN_USER=www-data \
    APACHE_RUN_GROUP=www-data \
    HOME="/root" \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    TERM=xterm

ARG MYTHTV_UID=2021
ARG MYTHTV_GID=100

# Expose ports
EXPOSE 3389 5000/udp 5002/udp 5004/udp 6543 6544 6760 65001 65001/udp 

# Add local files from git repo
ADD src/ /root/

# set volumes
VOLUME /home/mythtv /var/log/apache2 /var/log/mythtv

RUN zypper --gpg-auto-import-keys ar -f \
  http://packman.inode.at/suse/openSUSE_Leap_42.2/ packman && \
zypper ar -G ftp://ovulator/opensuse/depot/42.2-x86_64 local && \
zypper --gpg-auto-import-keys ref -s && \
zypper --non-interactive update && \

zypper --non-interactive in wget less net-tools w3m lynx curl which vim \
  apache2 php5 mariadb-client perl-XML-Twig glibc-locale glibc-i18ndata \
  psmisc xauth openssh xterm \
  mythtv-backend mythweb python-mythtv python-xml php-mythtv mythtv-setup && \

echo "Listen 6760" >>/etc/apache2/listen.conf && \
mv /root/000-default-myth-opensuse.conf /etc/apache2/vhosts.d/000-default-myth.conf && \
mv /root/mythweb-opensuse.conf /etc/apache2/vhosts.d/mythweb.conf && \
mv /root/my.cnf /etc/my.cnf && \

usermod -u $MYTHTV_UID mythtv && \
usermod -g $MYTHTV_GID mythtv && \

# create/place required files/folders
mkdir -p /home/mythtv/.mythtv /var/lib/mythtv /var/log/mythtv /root/.mythtv && \

echo "mythtv:mythtv" | chpasswd && \
usermod -s /bin/bash -d /home/mythtv mythtv && \
chown -R mythtv:users /var/lib/mythtv /var/log/mythtv && \
localedef -i en_US -f UTF-8 en_US.UTF-8 ; \

# clean up
zypper clean && \
rm -rf /tmp/* /var/tmp/* /var/cache/zypp \
/usr/share/man /usr/share/groff /usr/share/info \
/usr/share/lintian /usr/share/linda /var/cache/man

ENTRYPOINT ["/root/entrypoint.sh"]
