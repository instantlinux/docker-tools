FROM jenkins:2.32.2

ARG _JENKINS_VERSION=2.32.2
ARG _JENKINS_REF=/usr/share/jenkins/ref
ARG _DOCKER_DOWNLOADS=https://github.com/docker/compose/releases/download
ARG _COMPOSE_VERSION=1.11.2
ARG _COMPOSE_URL=${_DOCKER_DOWNLOADS}/${_COMPOSE_VERSION}/docker-compose-Linux-x86_64

ENV JENKINS_DEFAULT_ADMIN_USER='admin'
ENV JENKINS_DEFAULT_ADMIN_PASS='changeme'

# expose port for artifactory reverse proxy
EXPOSE 8082

USER root

# install  docker and docker-compose
RUN curl -fsSL https://test.docker.com/ | sh \
    && curl -o /usr/local/bin/docker-compose -L ${_COMPOSE_URL} \
    && chmod +x /usr/local/bin/docker-compose

USER jenkins

RUN echo ${_JENKINS_VERSION} > ${_JENKINS_REF}/jenkins.install.UpgradeWizard.state \
    && echo ${_JENKINS_VERSION} > ${_JENKINS_REF}/jenkins.install.InstallUtil.lastExecVersion

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh $(cat ${_JENKINS_REF}/plugins.txt | tr '\n' ' ')

COPY files/jenkins-master/executors.groovy ${_JENKINS_REF}/init.groovy.d/
COPY files/jenkins-master/default-user.groovy ${_JENKINS_REF}/init.groovy.d/
