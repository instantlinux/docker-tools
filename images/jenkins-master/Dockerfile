FROM openjdk:8u121-jdk-alpine
ARG BUILD_DATE
ARG VCS_REF
LABEL org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.license=Apache-2.0 \
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
    JENKINS_LIBRARY=git@git.instantlinux.net:richb/jenkinslib \
    JENKINS_OPTS="--logfile=/var/log/jenkins/jenkins.log --webroot=/var/cache/jenkins/war" \
    JENKINS_REF=/usr/share/jenkins/ref \
    JENKINS_SLAVE_AGENT_PORT=50000 \
    JENKINS_URL=http://jenkins.domain.com \
    MASTER_EXECUTORS=2 \
    SMTP_ADMIN_ADDRESS="Jenkins <no-reply@domain.com>" \
    SMTP_SMARTHOST=mail.domain.com \
    TZ=UTC

ARG _COMPOSE_VERSION=1.15
ARG _DOCKER_DOWNLOADS=https://github.com/docker/compose/releases/download
ARG _COMPOSE_URL=${_DOCKER_DOWNLOADS}/${_COMPOSE_VERSION}/docker-compose-Linux-x86_64
ARG _JENKINS_VERSION=2.74
ARG _TINI_DOWNLOADS=https://github.com/krallin/tini/releases/download
ARG _TINI_VERSION=0.15.0
ARG DOCKER_GID=485
ARG JENKINS_UID=1000
# sha256sum values for each download
ARG COMPOSE_SHA=0019dfc4b32d63c1392aa264aed2253c1e0c2fb09216f8e2cc269bbfb8bb49b5
ARG JENKINS_SHA=9f37140d0ccb6a9aa7c3c8a522a79b37bd1123edddca0e7f8f6dd579ffe8cb86
ARG TINI_SHA=4007655082f573603c02bc1d2137443c8e153af047ffd088d02ccc01e6f06170

# gid for docker must match that on container host
RUN addgroup -g ${DOCKER_GID} docker && \
    adduser -D -h "$JENKINS_HOME" -u $JENKINS_UID -s /bin/bash jenkins && \
    apk add --update --no-cache bash curl docker openssh-client su-exec \
      ttf-dejavu tzdata unzip wget zip && \
    cp /usr/share/zoneinfo/$TZ /etc/localtime && \
    echo $TZ >/etc/timezone && \
    mkdir -p /usr/share/jenkins && \

# Download Tini, Docker-compose, Jenkins
    curl -fL ${_TINI_DOWNLOADS}/v${_TINI_VERSION}/tini-static -o /bin/tini && \
    curl -L ${_COMPOSE_URL} -o /usr/local/bin/docker-compose && \
    curl -fL ${JENKINS_DOWNLOADS}/war/$_JENKINS_VERSION/jenkins.war -o /usr/share/jenkins/jenkins.war && \

# Verify downloads and set up paths
    echo "$TINI_SHA  /bin/tini" > /tmp/checksums && \
    echo "$COMPOSE_SHA  /usr/local/bin/docker-compose" >> /tmp/checksums && \
    echo "$JENKINS_SHA  /usr/share/jenkins/jenkins.war" >> /tmp/checksums && \
    sha256sum -c /tmp/checksums && \
    chmod +x /bin/tini /usr/local/bin/docker-compose && \
    mkdir /var/log/jenkins /var/cache/jenkins && \
    chown -R jenkins:jenkins /var/log/jenkins /var/cache/jenkins \
      /etc/timezone /etc/localtime

# Configuration:
#  Put groovy scripts under ref/init.groovy.d/; plugins in ref/plugins/
#  Put configuration xml files at ref/ top-level
COPY ref/ $JENKINS_REF
COPY entrypoint.sh /usr/local/bin/
COPY plugins.sh plugins.txt /tmp/
RUN /tmp/plugins.sh /tmp/plugins.txt && rm /tmp/*

EXPOSE 8080 50000
VOLUME $JENKINS_HOME
USER jenkins
ENTRYPOINT ["/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]
