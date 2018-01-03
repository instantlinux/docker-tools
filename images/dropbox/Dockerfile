FROM debian:stretch-slim
MAINTAINER Rich Braun "docker@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=Apache-2.0 \
    org.label-schema.name=dropbox \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV DEBIAN_FRONTEND=noninteractive \
    UID=1000

ARG USERNAME=user

RUN apt-get -yq update && \
    apt-get install -yq ca-certificates curl python && \
    useradd -u $UID -m -s /bin/sh -c "Dropbox user" $USERNAME && \
    cd /home/$USERNAME && \
    curl -sLo /usr/local/bin/dropbox-cli \
      https://www.dropbox.com/download?dl=packages/dropbox.py && \
    curl -sL "https://www.dropbox.com/download?plat=lnx.x86_64" \
      | tar xzf -  && \
    mkdir .dropbox Dropbox && \
    chmod +x /usr/local/bin/dropbox-cli && \
    chown -R $USERNAME /home/$USERNAME && \
    apt-get clean && rm -fr /var/lib/apt/lists/* /var/log/*

WORKDIR /home/$USERNAME/Dropbox
VOLUME /home/$USERNAME/Dropbox /home/$USERNAME/.dropbox
EXPOSE 17500

CMD ["sh", "-c", \
     "usermod -u $UID user ; chown -R $UID /home/user ; \
      exec su user -c /home/user/.dropbox-dist/dropboxd"]
