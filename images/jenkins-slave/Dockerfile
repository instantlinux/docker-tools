FROM openjdk:8u171-jdk-alpine3.8
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=Apache-2.0 \
    org.label-schema.name=jenkins-slave \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV SWARM_CLIENT_EXECUTORS=4 \
    SWARM_CLIENT_JAR=/opt/jenkins-swarm/swarm-client.jar \
    SWARM_CLIENT_LABELS= \
    SWARM_CLIENT_NAME= \
    SWARM_CLIENT_PARAMETERS=-disableSslVerification \
    SWARM_DELAY_START= \
    SWARM_ENV_FILE= \
    SWARM_JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk \
    SWARM_JENKINS_SECRET=jenkins-agent-password \
    SWARM_JENKINS_USER=jenkins \
    SWARM_MASTER_URL=http://jenkins:8080 \
    SWARM_VM_PARAMETERS=-Dfile.encoding=UTF-8 \
    SWARM_WORKDIR=/opt/jenkins \
    TZ=UTC
    
ARG _CLIENT_VERSION=3.13
ARG _COMPOSE_VERSION=1.22.0
ARG _DOCKER_VERSION=18.06.1-r0
ARG _PYCRYPTOGRAPHY_VERSION=2.3.1-r1
ARG _TINI_VERSION=0.18.0
ARG _DOCKER_DOWNLOADS=https://github.com/docker/compose/releases/download
ARG _COMPOSE_URL=${_DOCKER_DOWNLOADS}/${_COMPOSE_VERSION}/docker-compose-Linux-x86_64
ARG _PLUGIN_DOWNLOADS=https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client
ARG _TINI_DOWNLOADS=https://github.com/krallin/tini/releases/download
ARG DOCKER_GID=485
ARG JENKINS_UID=1000
ARG CLIENT_SHA=85197cced609bb36efc677813bcd3242813569970ff32bef49a10ee6ad7fb630
ARG COMPOSE_SHA=f679a24b93f291c3bffaff340467494f388c0c251649d640e661d509db9d57e9
ARG TINI_SHA=eadb9d6e2dc960655481d78a92d2c8bc021861045987ccd3e27c7eae5af0cf33

COPY requirements.txt /root/

RUN addgroup -g $DOCKER_GID docker && \
    mkdir -p $SWARM_WORKDIR `dirname $SWARM_CLIENT_JAR` && \
    adduser -D -h $SWARM_WORKDIR -u $JENKINS_UID -G docker \
      -s /bin/bash $SWARM_JENKINS_USER && \
    echo '@edge http://dl-cdn.alpinelinux.org/alpine/edge/main' \
      >>/etc/apk/repositories && \
    apk add --update --no-cache \
      bash curl docker==$_DOCKER_VERSION gcc git gzip make musl-dev \
      openssh-client python python-dev \
      py-cryptography@edge==$_PYCRYPTOGRAPHY_VERSION py-pip py-virtualenv \
      tar tzdata uwsgi-python wget && \
    cp /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ >/etc/timezone && \
    curl -sLo $SWARM_CLIENT_JAR \
      $_PLUGIN_DOWNLOADS/$_CLIENT_VERSION/swarm-client-$_CLIENT_VERSION.jar && \
    curl -sLo /bin/tini ${_TINI_DOWNLOADS}/v${_TINI_VERSION}/tini-static && \
    curl -sLo /usr/local/bin/docker-compose ${_COMPOSE_URL} && \
\
# Verify downloads and set up paths
    echo "$CLIENT_SHA  $SWARM_CLIENT_JAR" > /tmp/checksums && \
    echo "$TINI_SHA  /bin/tini" >> /tmp/checksums && \
    echo "$COMPOSE_SHA  /usr/local/bin/docker-compose" >> /tmp/checksums && \
    sha256sum -c /tmp/checksums && rm /tmp/checksums && \
    chmod +x /bin/tini /usr/local/bin/docker-compose && \
    pip install --upgrade pip && \
    pip install -r /root/requirements.txt && \
    chown $SWARM_JENKINS_USER $SWARM_WORKDIR /etc/localtime /etc/timezone && \
    rm -f /var/cache/apk/*

WORKDIR $SWARM_WORKDIR
VOLUME $SWARM_WORKDIR
COPY entrypoint.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/entrypoint.sh

USER jenkins
ENTRYPOINT ["/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["swarm"]
