FROM docker:19.03.5
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

ARG COMPOSE_VERSION=1.25.0
ARG KUBECTL_VERSION=1.15.3
ARG MUSL_VERSION=1.1.24-r0
ARG PYTHON_VERSION=3.8.1-r0
ARG PYCRYPTOGRAPHY_VERSION=2.8-r1
ARG _DOCKER_DOWNLOADS=https://github.com/docker/compose/releases/download
ARG _KUBECTL_DOWNLOADS=https://storage.googleapis.com/kubernetes-release/release
ARG _COMPOSE_URL=${_DOCKER_DOWNLOADS}/${COMPOSE_VERSION}/docker-compose-Linux-x86_64
ARG _KUBECTL_URL=${_KUBECTL_DOWNLOADS}/v$KUBECTL_VERSION/bin/linux/amd64/kubectl
ARG DOCKER_GID=485
ARG BUILD_UID=1001
ARG COMPOSE_SHA=2bdab0bbf42583b4b77ee015cf908933c78f0572a7cb949a7dd8e200e6250221
ARG KUBECTL_SHA=6e805054a1fb2280abb53f75b57a1b92bf9c66ffe0d2cdcd46e81b079d93c322

COPY requirements.txt /root/

RUN addgroup -g $DOCKER_GID docker && \
    adduser -D -h $BUILD_DIR -u $BUILD_UID -G docker \
      -s /bin/bash $BUILD_USER && \
    apk add --update --no-cache \
      bash curl gcc gettext git gzip jq make musl==$MUSL_VERSION \
      musl-dev==$MUSL_VERSION openssh-client \
      python3==$PYTHON_VERSION python3-dev \
      py3-cryptography==$PYCRYPTOGRAPHY_VERSION py3-virtualenv tar \
      tzdata uwsgi-python wget && \
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
