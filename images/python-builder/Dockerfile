FROM alpine:3.15
MAINTAINER Rich Braun "richb@instantlinux.net"
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=Apache-2.0 \
    org.label-schema.name=python-builder \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV BUILD_DIR=/build \
    BUILD_USER=build \
    LANG=en_US \
    PYTHONPATH= \
    TZ=UTC

ARG BUILDX_VERSION=0.7.1
ARG COMPOSE_VERSION=1.29.2
ARG HELM_VERSION=3.9.0-r1
ARG KUBECTL_VERSION=1.20.4
ARG MUSL_VERSION=1.2.2-r7
ARG PIP_VERSION=20.2.3
ARG PYTHON_VERSION=3.9.7-r4
ARG PYCRYPTOGRAPHY_VERSION=3.3.2-r3
ARG PYPILLOW_VERSION=8.4.0-r3
ARG _DOCKER_DOWNLOADS=https://github.com/docker/compose/releases/download
ARG _KUBECTL_DOWNLOADS=https://storage.googleapis.com/kubernetes-release/release
ARG _BUILDX_URL=https://github.com/docker/buildx/releases/download/v${BUILDX_VERSION}/buildx-v${BUILDX_VERSION}.linux-amd64
ARG _COMPOSE_URL=${_DOCKER_DOWNLOADS}/${COMPOSE_VERSION}/docker-compose-Linux-x86_64
ARG _KUBECTL_URL=${_KUBECTL_DOWNLOADS}/v$KUBECTL_VERSION/bin/linux/amd64/kubectl
ARG DOCKER_GID=485
ARG BUILD_UID=1001
ARG BUILDX_SHA=22fcb78c66905bf6ddf198118aaa9838b0349a25347606264be17e4276d6d5fc
ARG COMPOSE_SHA=f3f10cf3dbb8107e9ba2ea5f23c1d2159ff7321d16f0a23051d68d8e2547b323
ARG KUBECTL_SHA=98e8aea149b00f653beeb53d4bd27edda9e73b48fed156c4a0aa1dabe4b1794c

COPY Pipfile* /root/

RUN addgroup -g $DOCKER_GID docker && \
    adduser -D -h $BUILD_DIR -u $BUILD_UID -G docker \
      -s /bin/bash $BUILD_USER && \
    echo '@testing http://dl-cdn.alpinelinux.org/alpine/edge/testing' \
      >>/etc/apk/repositories && \
    apk add --update --no-cache \
      bash curl docker-cli gcc gettext git gzip jq libffi-dev make \
      musl==$MUSL_VERSION musl-dev==$MUSL_VERSION openssh-client \
      python3==$PYTHON_VERSION python3-dev py3-authlib py3-boto3 py3-botocore \
      py3-cachetools py3-cffi py3-cryptography==$PYCRYPTOGRAPHY_VERSION \
      py3-pycryptodomex py3-flask py3-flask-babel py3-greenlet \
      py3-itsdangerous py3-passlib \
      py3-pillow=$PYPILLOW_VERSION py3-pip py3-requests py3-virtualenv \
      helm@testing=$HELM_VERSION sqlite tar tzdata wget && \
    cp /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ >/etc/timezone && \
    mkdir -p /usr/lib/docker/cli-plugins && \
    curl -sLo /usr/lib/docker/cli-plugins/docker-buildx $_BUILDX_URL && \
    curl -sLo /usr/local/bin/docker-compose ${_COMPOSE_URL} && \
    curl -sLo /usr/local/bin/kubectl ${_KUBECTL_URL} && \
    echo -e "$BUILDX_SHA  /usr/lib/docker/cli-plugins/docker-buildx\n$COMPOSE_SHA" \
      " /usr/local/bin/docker-compose\n$KUBECTL_SHA" \
      " /usr/local/bin/kubectl" | sha256sum -c && \
    chmod +x /usr/lib/docker/cli-plugins/docker-buildx \
      /usr/local/bin/docker-compose /usr/local/bin/kubectl && \
    pip install --upgrade pipenv pip==$PIP_VERSION && \
    cd /root && pipenv install --system --deploy && pip freeze && \
    mkdir -p /certs/client && \
    chown $BUILD_USER /certs/client /etc/localtime /etc/timezone && \
    rm -f /var/cache/apk/*

WORKDIR $BUILD_DIR
VOLUME $BUILD_DIR
COPY docker-entrypoint.sh entrypoint.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/entrypoint.sh

USER $BUILD_USER
ENTRYPOINT ["entrypoint.sh"]
CMD ["sh"]
