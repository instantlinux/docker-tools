FROM blacklabelops/jenkins-swarm:2.2
USER root

ARG DOCKER_DOWNLOADS=https://github.com/docker/compose/releases/download
ENV COMPOSE_VERSION=1.11.2

RUN groupadd -g 485 docker
RUN curl -fsSL https://test.docker.com/ | sh

RUN curl -o /usr/local/bin/docker-compose \
    -L ${DOCKER_DOWNLOADS}/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m) && \
    chmod +x /usr/local/bin/docker-compose && \
    usermod -a -G docker swarmslave && \
    yum -y install epel-release && \
    yum -y install python-pip python-virtualenv gcc make

ADD src/ /root/
RUN pip install -r /root/requirements.txt

USER swarmslave
