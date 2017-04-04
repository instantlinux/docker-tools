FROM dockerhub.instantlinux.net:5000/foundation:16.04.20170402

## adapted from https://github.com/blacklabelops/jenkins-swarm
## MAINTAINER Steffen Bleul <sbl@blacklabelops.com>

MAINTAINER Rich Braun <richb@instantlinux.net>

# Jenkins Swarm Version
ARG SWARM_VERSION=2.2
ARG CONTAINER_USER=swarmslave
ARG CONTAINER_UID=1000
ARG CONTAINER_GROUP=swarmslave
ARG CONTAINER_GID=1000

# Container Internal Environment Variables
ENV SWARM_HOME=/opt/jenkins-swarm \
    SWARM_JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre \
    SWARM_WORKDIR=/opt/jenkins

RUN /usr/sbin/groupadd --gid $CONTAINER_GID $CONTAINER_GROUP && \
    /usr/sbin/useradd --uid $CONTAINER_UID --gid $CONTAINER_GID --shell /bin/bash $CONTAINER_USER && \
    # Install Development Tools
    apt-get update && apt-get install -y \
        wget curl tar gzip mercurial git openjdk-8-jre-headless && \
    # Install Git-LFS
    export GIT_LFS_VERSION=1.4.1 && \
    export GIT_LFS_SHA=f02e5f720aad2738458426545d3b9626e7c7410d && \
    wget -O /tmp/git-lfs-linux-amd64.tar.gz https://github.com/github/git-lfs/releases/download/v${GIT_LFS_VERSION}/git-lfs-linux-amd64-${GIT_LFS_VERSION}.tar.gz && \
    sha1sum /tmp/git-lfs-linux-amd64.tar.gz && \
    echo "$GIT_LFS_SHA /tmp/git-lfs-linux-amd64.tar.gz" | sha1sum -c - && \
    tar xfv /tmp/git-lfs-linux-amd64.tar.gz -C /tmp && \
    cd /tmp/git-lfs-${GIT_LFS_VERSION}/ && bash -c "/tmp/git-lfs-${GIT_LFS_VERSION}/install.sh" && \
    git lfs install && \
    # Install Tini Zombie Reaper And Signal Forwarder
    export TINI_VERSION=0.10.0 && \
    export TINI_SHA=7d00da20acc5c3eb21d959733917f6672b57dabb && \
    curl -fsSL https://github.com/krallin/tini/releases/download/v${TINI_VERSION}/tini-static -o /bin/tini && \
    chmod +x /bin/tini && \
    sha1sum /bin/tini && \
    echo "$TINI_SHA /bin/tini" | sha1sum -c - && \
    # Install Jenkins Swarm-Slave
    export SWARM_SHA=731ca367119d4b46421c70367111f4c9902a2cb7 && \
    mkdir -p ${SWARM_HOME} && \
    wget --directory-prefix=${SWARM_HOME} \
      https://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/${SWARM_VERSION}/swarm-client-${SWARM_VERSION}-jar-with-dependencies.jar && \
    sha1sum ${SWARM_HOME}/swarm-client-${SWARM_VERSION}-jar-with-dependencies.jar && \
    echo "$SWARM_SHA ${SWARM_HOME}/swarm-client-${SWARM_VERSION}-jar-with-dependencies.jar" | sha1sum -c - && \
    mv ${SWARM_HOME}/swarm-client-${SWARM_VERSION}-jar-with-dependencies.jar ${SWARM_HOME}/swarm-client-jar-with-dependencies.jar && \
    mkdir -p ${SWARM_WORKDIR} && \
    chown -R ${CONTAINER_USER}:${CONTAINER_GROUP} ${SWARM_HOME} ${SWARM_WORKDIR} && \
    chmod +x ${SWARM_HOME}/swarm-client-jar-with-dependencies.jar

RUN rm -rf /var/lib/apt/lists/* /var/log/*log /var/apt/*log \
  /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb \
  /var/cache/apt/*.bin

# Entrypoint Environment Variables
ENV SWARM_VM_PARAMETERS= \
    SWARM_MASTER_URL= \
    SWARM_VM_PARAMETERS= \
    SWARM_JENKINS_USER= \
    SWARM_JENKINS_PASSWORD= \
    SWARM_CLIENT_EXECUTORS= \
    SWARM_CLIENT_LABELS= \
    SWARM_CLIENT_NAME=

USER $CONTAINER_USER
WORKDIR $SWARM_WORKDIR
VOLUME $SWARM_WORKDIR
COPY imagescripts/docker-entrypoint.sh ${SWARM_HOME}/docker-entrypoint.sh
ENTRYPOINT ["/bin/tini","--","/opt/jenkins-swarm/docker-entrypoint.sh"]
CMD ["swarm"]
