FROM openjdk:8u191-jre-alpine3.9
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=MIT \
    org.label-schema.name=jenkins-master \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-url=https://github.com/instantlinux/docker-tools

ENV ARTIFACTORY_URI=artifactory.domain.com \
    ARTIFACTORY_USER=artifactory \
    ARTIFACTORY_USER_SECRET=artifactory-user-password \
    CA_CERTIFICATES_JAVA_VERSION=20140324 \
    COPY_REFERENCE_FILE_LOG=/var/jenkins_home/copy_reference_file.log \
    JAVA_OPTS="-Xmx8192m -Djenkins.install.runSetupWizard=false" \
    JENKINS_ADMIN_USER=admin \
    JENKINS_ADMIN_SECRET=jenkins-admin-password \
    JENKINS_DOWNLOADS=https://updates.jenkins-ci.org/download \
    JENKINS_HOME=/var/jenkins_home \
    JENKINS_LIBRARY=git@git.domain.com:user/jenkinslib \
    JENKINS_OPTS="--logfile=/var/log/jenkins/jenkins.log --webroot=/var/cache/jenkins/war" \
    JENKINS_REF=/usr/share/jenkins/ref \
    JENKINS_SLAVE_AGENT_PORT=50000 \
    JENKINS_URL=http://jenkins.domain.com \
    MASTER_EXECUTORS=2 \
    SMTP_ADMIN_ADDRESS="Jenkins <no-reply@domain.com>" \
    SMTP_SMARTHOST=mail.domain.com \
    TZ=UTC

ARG _COMPOSE_VERSION=1.22.0
ARG _DOCKER_DOWNLOADS=https://github.com/docker/compose/releases/download
ARG _COMPOSE_URL=${_DOCKER_DOWNLOADS}/${_COMPOSE_VERSION}/docker-compose-Linux-x86_64
ARG _JENKINS_VERSION=2.150.3
ARG _TINI_DOWNLOADS=https://github.com/krallin/tini/releases/download
ARG _TINI_VERSION=0.18.0
ARG DOCKER_GID=485
ARG JENKINS_UID=1000
# sha256sum values for each download
ARG COMPOSE_SHA=f679a24b93f291c3bffaff340467494f388c0c251649d640e661d509db9d57e9
ARG JENKINS_SHA=4fc2700a27a6ccc53da9d45cc8b2abd41951b361e562e1a1ead851bea61630fd
ARG TINI_SHA=eadb9d6e2dc960655481d78a92d2c8bc021861045987ccd3e27c7eae5af0cf33

# gid for docker must match that on container host
RUN addgroup -g ${DOCKER_GID} docker && \
    adduser -D -h "$JENKINS_HOME" -u $JENKINS_UID -s /bin/bash jenkins && \
    apk add --update --no-cache bash curl docker git openssh-client su-exec \
      ttf-dejavu tzdata unzip wget zip && \
    touch /etc/localtime /etc/timezone && \
    mkdir -p /usr/share/jenkins && \
\
# Download Tini, Docker-compose, Jenkins
    curl -sLo /bin/tini \
      ${_TINI_DOWNLOADS}/v${_TINI_VERSION}/tini-static && \
    curl -sLo /usr/local/bin/docker-compose ${_COMPOSE_URL} && \
    curl -sLo /usr/share/jenkins/jenkins.war \
      ${JENKINS_DOWNLOADS}/war/$_JENKINS_VERSION/jenkins.war && \
\
# Verify downloads and set up paths
    echo "$TINI_SHA  /bin/tini" > /tmp/checksums && \
    echo "$COMPOSE_SHA  /usr/local/bin/docker-compose" >> /tmp/checksums && \
    echo "$JENKINS_SHA  /usr/share/jenkins/jenkins.war" >> /tmp/checksums && \
    sha256sum -c /tmp/checksums && \
    chmod +x /bin/tini /usr/local/bin/docker-compose && \
    mkdir /var/log/jenkins /var/cache/jenkins && \
    chown -R jenkins:jenkins /var/log/jenkins /var/cache/jenkins \
      /etc/timezone /etc/localtime && \
    rm -f /var/cache/apk/*

# Configuration:
#  Put groovy scripts under ref/init.groovy.d/; plugins in ref/plugins/
#  Put configuration xml files at ref/ top-level
COPY ref/ $JENKINS_REF
COPY plugins.sh plugins.txt /tmp/
RUN /tmp/plugins.sh /tmp/plugins.txt && rm /tmp/*
COPY entrypoint.sh /usr/local/bin/
RUN chmod -R g+rX,o+rX $JENKINS_REF /usr/local/bin/entrypoint.sh

EXPOSE 8080 50000
VOLUME $JENKINS_HOME
USER jenkins
ENTRYPOINT ["/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
