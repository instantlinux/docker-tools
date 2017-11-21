## jenkins-master
[![](https://images.microbadger.com/badges/version/instantlinux/jenkins-master.svg)](https://microbadger.com/images/instantlinux/jenkins-master "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/jenkins-master.svg)](https://microbadger.com/images/instantlinux/jenkins-master "Image badge") [![](https://images.microbadger.com/badges/commit/instantlinux/jenkins-master.svg)](https://microbadger.com/images/instantlinux/jenkins-master "Commit badge")

Builds a current (2.73.x) version of Jenkins, with the list of plugins
shown in plugins.txt along with configuration settings defined in the ref
directory.

This is a companion to the jenkins-slave image, which can be auto-
configured via the (installed) swarm plugin or can be launched on
demand via the docker-slaves plugin.

### Usage
Set the variables as defined below, and run the docker-compose stack.

### Variables

Variable | Default | Description
-------- | ------- | -----------
ARTIFACTORY_URI | artifactory.domain.com | URI to local repo
ARTIFACTORY_USER | artifactory | username for artifactory access
ARTIFACTORY_USER_SECRET | artifactory-user-password | name of secret, see below
CA_CERTIFICATES_JAVA_VERSION | 20140324 | Java version for CA
COPY_REFERENCE_FILE_LOG | /var/jenkins_home/copy_reference_file.log | log file seen after ref copy
JAVA_OPTS | -Xmx8192m -Djenkins.install.runSetupWizard=false | Java options
JENKINS_ADMIN_USER | admin | Jenkins admin
JENKINS_ADMIN_SECRET | jenkins-admin-password | name of secret
JENKINS_DOWNLOADS | https://updates.jenkins-ci.org/download | URL of plugins site
JENKINS_HOME | /var/jenkins_home | Jenkins home directory
JENKINS_LIBRARY | git@git.domain.com:user/jenkinslib | Groovy library
JENKINS_OPTS | --logfile=/var/log/jenkins/jenkins.log --webroot=/var/cache/jenkins/war | Jenkins command line options
JENKINS_REF | /usr/share/jenkins/ref | Reference dir (configs/plugins)
JENKINS_SLAVE_AGENT_PORT | 50000 | Slave TCP comm port
JENKINS_URL | http://jenkins.domain.com | External Jenkins URL
MASTER_EXECUTORS | 2 | Executor slots on master
SMTP_ADMIN_ADDRESS | "Jenkins <no-reply@domain.com>" | From: address for notices
SMTP_SMARTHOST | mail.domain.com | Smarthost for sending messages
TZ | UTC | time zone

### Secrets
Name | Description
---- | -----------
artifactory-user-password | password for artifactory repo access
jenkins-admin-password | password for new Jenkins admin user

[![](https://images.microbadger.com/badges/license/instantlinux/jenkins-master.svg)](https://microbadger.com/images/instantlinux/jenkins-master "License badge")
