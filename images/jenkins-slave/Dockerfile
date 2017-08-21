FROM openjdk:8u121-jdk-alpine

ENV SWARM_CLIENT_EXECUTORS=4 \
    SWARM_CLIENT_JAR=/opt/jenkins-swarm/swarm-client.jar \
    SWARM_CLIENT_LABELS= \
    SWARM_CLIENT_NAME= \
    SWARM_CLIENT_PARAMETERS=-disableSslVerification \
    SWARM_DELAY_START= \
    SWARM_ENV_FILE= \
    SWARM_JAVA_HOME=/usr/lib/jvm/java-1.8-openjdk \
    SWARM_JENKINS_SECRET=jenkins-user-password \
    SWARM_JENKINS_USER=jenkins \
    SWARM_MASTER_URL=http://jenkins:8080 \
    SWARM_VM_PARAMETERS=-Dfile.encoding=UTF-8 \
    SWARM_WORKDIR=/opt/jenkins \
    TZ=UTC
    
ARG COMPOSE_VERSION=1.15
ARG _DOCKER_DOWNLOADS=https://github.com/docker/compose/releases/download
ARG _COMPOSE_URL=${_DOCKER_DOWNLOADS}/${_COMPOSE_VERSION}/docker-compose-Linux-x86_64
ARG _PLUGIN_DOWNLOADS=https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client
ARG _CLIENT_VERSION=3.4
ARG _TINI_DOWNLOADS=https://github.com/krallin/tini/releases/download
ARG _TINI_VERSION=0.15.0
ARG DOCKER_GID=485
ARG JENKINS_UID=1000
ARG CLIENT_SHA=931b026d311023fe19c130211bef137f4873fafc19e4a41bca8fa41ffbb27a49
ARG COMPOSE_SHA=0019dfc4b32d63c1392aa264aed2253c1e0c2fb09216f8e2cc269bbfb8bb49b5
ARG TINI_SHA=4007655082f573603c02bc1d2137443c8e153af047ffd088d02ccc01e6f06170

COPY requirements.txt /root/

RUN addgroup -g $DOCKER_GID docker && \
    mkdir -p $SWARM_WORKDIR `dirname $SWARM_CLIENT_JAR` && \
    adduser -D -h $SWARM_WORKDIR -u $JENKINS_UID -G docker \
      -s /bin/bash $SWARM_JENKINS_USER && \
    apk add --update --no-cache \
      bash curl docker gcc git gzip make python py-pip py-virtualenv tar \
      tzdata uwsgi-python wget && \
    cp /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ >/etc/timezone && \
    curl -o ${SWARM_CLIENT_JAR} -fL \
      ${_PLUGIN_DOWNLOADS}/${_CLIENT_VERSION}/swarm-client-${_CLIENT_VERSION}.jar  && \
    curl -o /bin/tini -fL ${_TINI_DOWNLOADS}/v${_TINI_VERSION}/tini-static && \
    curl -L ${_COMPOSE_URL} -o /usr/local/bin/docker-compose && \

# Verify downloads and set up paths
    echo "$CLIENT_SHA  $SWARM_CLIENT_JAR" > /tmp/checksums && \
    echo "$TINI_SHA  /bin/tini" >> /tmp/checksums && \
    echo "$COMPOSE_SHA  /usr/local/bin/docker-compose" >> /tmp/checksums && \
    sha256sum -c /tmp/checksums && rm /tmp/checksums && \
    chmod +x /bin/tini /usr/local/bin/docker-compose && \
    pip install -r /root/requirements.txt && \
    chown $SWARM_JENKINS_USER $SWARM_WORKDIR /etc/localtime /etc/timezone

WORKDIR $SWARM_WORKDIR
VOLUME $SWARM_WORKDIR
COPY entrypoint.sh /usr/local/bin/
USER jenkins
ENTRYPOINT ["/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
CMD ["swarm"]
