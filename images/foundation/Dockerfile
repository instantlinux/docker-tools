FROM ubuntu:16.04
MAINTAINER Rich Braun "richb@instantlinux.net"

ENV DEBIAN_FRONTEND=noninteractive

RUN \
  apt-get -yqq update && \
  apt-get -yq upgrade && \
  apt-get -yq install python-pip python-virtualenv gcc make

RUN rm -rf /var/lib/apt/lists/* /var/log/*log /var/apt/*log \
  /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb \
  /var/cache/apt/*.bin

CMD ["/bin/bash"]
