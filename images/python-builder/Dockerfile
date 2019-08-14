FROM docker:18.06.3
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=Apache-2.0 \
    org.label-schema.name=python-builder \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV BUILD_DIR=/build \
    BUILD_USER=build \
    TZ=UTC

ARG COMPOSE_VERSION=1.24.0
ARG KUBECTL_VERSION=1.14.1
ARG MUSL_VERSION=1.1.20-r5
ARG PYTHON_VERSION=3.6.8-r2
ARG PYCRYPTOGRAPHY_VERSION=2.4.2-r2
ARG _DOCKER_DOWNLOADS=https://github.com/docker/compose/releases/download
ARG _KUBECTL_DOWNLOADS=https://storage.googleapis.com/kubernetes-release/release
ARG _COMPOSE_URL=${_DOCKER_DOWNLOADS}/${COMPOSE_VERSION}/docker-compose-Linux-x86_64
ARG _KUBECTL_URL=${_KUBECTL_DOWNLOADS}/v$KUBECTL_VERSION/bin/linux/amd64/kubectl
ARG DOCKER_GID=485
ARG BUILD_UID=1001
ARG COMPOSE_SHA=bee6460f96339d5d978bb63d17943f773e1a140242dfa6c941d5e020a302c91b
ARG KUBECTL_SHA=829c00f0401a0887154d640349a974055a87199714a8d7d741d635ed20c70ee9

COPY requirements.txt /root/

RUN addgroup -g $DOCKER_GID docker && \
    adduser -D -h $BUILD_DIR -u $BUILD_UID -G docker \
      -s /bin/bash $BUILD_USER && \
    echo '@edge http://dl-cdn.alpinelinux.org/alpine/edge/main' \
      >>/etc/apk/repositories && \
    apk add --update --no-cache \
      bash curl gcc gettext git gzip jq make musl==$MUSL_VERSION \
      musl-dev==$MUSL_VERSION openssh-client \
      python3==$PYTHON_VERSION python3-dev \
      py3-cryptography@edge==$PYCRYPTOGRAPHY_VERSION py3-virtualenv tar \
      tzdata uwsgi-python3 wget && \
    cp /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ >/etc/timezone && \
    curl -sLo /usr/local/bin/docker-compose ${_COMPOSE_URL} && \
    curl -sLo /usr/local/bin/kubectl ${_KUBECTL_URL} && \
    echo -e "$COMPOSE_SHA  /usr/local/bin/docker-compose\n$KUBECTL_SHA" \
        " /usr/local/bin/kubectl" | sha256sum -c && \
    chmod +x /usr/local/bin/docker-compose /usr/local/bin/kubectl && \
    pip3 install --upgrade pip && \
    pip install -r /root/requirements.txt && \
    chown $BUILD_USER /etc/localtime /etc/timezone && \
    rm -f /var/cache/apk/*

WORKDIR $BUILD_DIR
VOLUME $BUILD_DIR
COPY entrypoint.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/entrypoint.sh

USER $BUILD_USER
