FROM debian:jessie-slim
MAINTAINER Rich Braun "docker@instantlinux.net"

ENV DEBIAN_FRONTEND=noninteractive

RUN \
  apt-key adv --keyserver keys.gnupg.net --recv-keys 8507EFA5 && \
  echo "deb http://repo.percona.com/apt wheezy main" > /etc/apt/sources.list.d/percona.list && \
  echo "deb-src http://repo.percona.com/apt wheezy main" >> /etc/apt/sources.list.d/percona.list && \
  apt-get -yqq update && \
  apt-get install -yqq \
    percona-xtradb-cluster-garbd-2.x locales && \
  locale-gen en_US.UTF-8

EXPOSE 3306 4444 4567 4568
