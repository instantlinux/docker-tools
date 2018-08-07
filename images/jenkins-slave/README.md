## jenkins-master
[![](https://images.microbadger.com/badges/version/instantlinux/jenkins-slave.svg)](https://microbadger.com/images/instantlinux/jenkins-slave "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/jenkins-slave.svg)](https://microbadger.com/images/instantlinux/jenkins-slave "Image badge") [![](https://images.microbadger.com/badges/commit/instantlinux/jenkins-slave.svg)](https://microbadger.com/images/instantlinux/jenkins-slave "Commit badge")

An image with basic build tools (python/gcc) for Jenkins
executors. This will automatically phone-home to the jenkins-master
image, using the swarm plugin.

### Usage
Set the variables as defined below, and run the docker-compose stack
found in jenkins-master.

### Variables

Variable | Default | Description
-------- | ------- | -----------
SWARM_CLIENT_EXECUTORS | 4 | Number of executor slots for this instance
SWARM_CLIENT_JAR | /opt/jenkins-swarm/swarm-client.jar | Jarfile path
SWARM_CLIENT_LABELS |  | Node labels
SWARM_CLIENT_NAME |  | Node name
SWARM_CLIENT_PARAMETERS | -disableSslVerification | CLI params for swarm client
SWARM_DELAY_START |  | Seconds to delay start
SWARM_ENV_FILE |  | File to execute at startup
SWARM_JAVA_HOME | /usr/lib/jvm/java-1.8-openjdk | JAVA_HOME location
SWARM_JENKINS_SECRET | jenkins-agent-password | Secret for jenkins user
SWARM_JENKINS_USER | jenkins | Jenkins username on master
SWARM_MASTER_URL | http://jenkins:8080 | Phone-home URL
SWARM_VM_PARAMETERS | -Dfile.encoding=UTF-8 | Java CLI params
SWARM_WORKDIR | /opt/jenkins | Workspace directory
TZ | UTC | time zone

### Secrets
Name | Description
---- | -----------
jenkins-agent-password | password for Jenkins user auth
repo-push | Docker registry credential

[![](https://images.microbadger.com/badges/license/instantlinux/jenkins-slave.svg)](https://microbadger.com/images/instantlinux/jenkins-slave "License badge")
