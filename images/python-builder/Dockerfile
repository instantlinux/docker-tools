FROM alpine:3.18
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

ARG BUILDX_VERSION=0.11.2
ARG COMPOSE_VERSION=2.20.2
ARG HELM_VERSION=3.11.3-r0
ARG KUBECTL_VERSION=1.26.7
ARG MUSL_VERSION=1.2.4-r1
ARG PIP_VERSION=23.2.1
ARG PYTHON_VERSION=3.11.4-r0
ARG PYCRYPTOGRAPHY_VERSION=40.0.2-r1
ARG PYPILLOW_VERSION=9.5.0-r1
ARG _DOCKER_DOWNLOADS=https://github.com/docker/compose/releases/download
ARG _KUBECTL_DOWNLOADS=https://storage.googleapis.com/kubernetes-release/release
ARG _BUILDX_URL=https://github.com/docker/buildx/releases/download/v${BUILDX_VERSION}/buildx-v${BUILDX_VERSION}.linux-amd64
ARG _COMPOSE_URL=${_DOCKER_DOWNLOADS}/v${COMPOSE_VERSION}/docker-compose-linux-x86_64
ARG _KUBECTL_URL=${_KUBECTL_DOWNLOADS}/v$KUBECTL_VERSION/bin/linux/amd64/kubectl
ARG DOCKER_GID=485
ARG BUILD_UID=1001
ARG BUILDX_SHA=311568ee69715abc46163fd688e56c77ab0144ff32e116d0f293bfc3470e75b7
ARG COMPOSE_SHA=b9385dabb7931636a3afc0aee94625ebff3bb29584493a87804afb6ebaf2d916
ARG KUBECTL_SHA=d9dc7741e5f279c28ef32fbbe1daa8ebc36622391c33470efed5eb8426959971

COPY Pipfile* /root/
RUN addgroup -g $DOCKER_GID docker && \
    adduser -D -h $BUILD_DIR -u $BUILD_UID -G docker \
      -s /bin/bash $BUILD_USER && \
    apk add --update --no-cache \
      bash curl docker-cli gcc gettext git gzip jq libffi-dev make \
      musl==$MUSL_VERSION musl-dev==$MUSL_VERSION openssh-client \
      python3==$PYTHON_VERSION python3-dev py3-authlib py3-boto3 py3-botocore \
      py3-cachetools py3-cffi py3-cryptography==$PYCRYPTOGRAPHY_VERSION \
      py3-pycryptodomex py3-greenlet \
      py3-itsdangerous py3-jinja2 py3-ldap3 py3-passlib \
      py3-pillow=$PYPILLOW_VERSION py3-pip py3-requests py3-virtualenv \
      py3-werkzeug helm=$HELM_VERSION sqlite tar tzdata wget && \
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
