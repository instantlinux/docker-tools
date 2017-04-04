#FROM blacklabelops/jenkins-swarm:2.2
FROM dockerhub.instantlinux.net:5000/jenkins-swarm:20170403
USER root

ARG DOCKER_DOWNLOADS=https://github.com/docker/compose/releases/download
ENV COMPOSE_VERSION=1.11.2

RUN groupadd -g 485 docker
RUN curl -fsSL https://test.docker.com/ | sh

RUN curl -o /usr/local/bin/docker-compose \
    -L ${DOCKER_DOWNLOADS}/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m) && \
    chmod +x /usr/local/bin/docker-compose && \
    usermod -a -G docker -d /opt/jenkins swarmslave && \
    apt-get install -y python-pip python-virtualenv gcc make
#    yum -y install epel-release && \
#    yum -y install python-pip python-virtualenv gcc make

ADD src/ /root/
RUN pip install -r /root/requirements.txt

USER swarmslave
