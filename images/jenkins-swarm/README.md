# Dockerized Jenkins Swarm-Slave

[![Circle CI](https://circleci.com/gh/blacklabelops/jenkins-swarm/tree/master.svg?style=svg)](https://circleci.com/gh/blacklabelops/jenkins-swarm/tree/master)
[![Image Layers](https://badge.imagelayers.io/blacklabelops/jenkins-swarm:latest.svg)](https://imagelayers.io/?images=blacklabelops/jenkins-swarm:latest 'Get your own badge on imagelayers.io')

## What's Inside

Installed Software:

  * Java 8
  * Subversion
  * Git
  * Github LFS
  * Mercurial
  * [Git LFS](https://git-lfs.github.com/)

Perfectly working with the following container: [blacklabelops/jenkins](https://github.com/blacklabelops/jenkins)

Blacklabelops swarm slaves can be found here: [blacklabelops/swarm](https://github.com/blacklabelops/swarm)

## Make It Short

In short, this container can be started arbitrary times and connect as build slaves to
a Jenkins master instance. You need 10 Java JDK 8 build slaves? You want to start 6 build slaves on your co-workers machine? Use this!

First start a master!

~~~~
$ docker run -d -p 8090:8080 --name jenkins blacklabelops/jenkins
~~~~

> This will pull the my jenkins container ready with swarm plugin and ready-to-use!

Now swarm the place!

~~~~
$ docker run -d --link jenkins blacklabelops/jenkins-swarm
$ docker run -d --link jenkins blacklabelops/jenkins-swarm
$ docker run -d --link jenkins blacklabelops/jenkins-swarm
~~~~

> This will start 3 Java JDK 8 build slaves, each with 4 build processors! This setup will
need no further setup as the swarm slave automatically connects to the linked jenkins.

## Setting Jenkins Master URL

Define your Jenkins master URL. This setup does not need linking. The URL can be specified
by the `SWARM_MASTER_URL` environment variable.

Example:

~~~~
$ docker run -d \
  -e "SWARM_MASTER_URL=http://192.168.59.103:8090/" \
  blacklabelops/jenkins-swarm
~~~~

> Connects to Jenkins Master at http://192.168.59.103:8090/

## Setting Jenkins-Swarm Parameters

You can define additional swarm parameters specified in the swarm client documentation
[Swarm Plugin Homepage](https://wiki.jenkins-ci.org/display/JENKINS/Swarm+Plugin). The swarm
parameters are simply attached and should not override parameters that are controlled by
environment variables, e.g. `SWARM_MASTER_URL`!

Example defining the title and description of a swarm client with the environment variable
`SWARM_CLIENT_PARAMETERS`:

~~~~
$ docker run -d \
  --link jenkins:jenkins \
	-e "SWARM_CLIENT_PARAMETERS=-name 'Super-Build' -description 'Super Client'" \
	blacklabelops/jenkins-swarm
~~~~

## Setting Jenkins Authentication

Authentication for the Jenkins master instance. Define username and password with the
following environment variables:

* `SWARM_JENKINS_USER`
* `SWARM_JENKINS_PASSWORD`

Example:

~~~~
$ docker run -d \
  --link jenkins_jenkins_1:jenkins \
	-e "SWARM_JENKINS_USER=jenkins" \
  -e "SWARM_JENKINS_PASSWORD=swordfish" \
	blacklabelops/jenkins-swarm
~~~~

> Note: Must be a valid Jenkins User for the Jenkins master instance.

Wanna try? Here, use this command for a suitable master:

~~~~
$ docker run -d --name jenkins_jenkins_1 \
	-e "SWARM_JENKINS_USER=jenkins" \
	-e "SWARM_JENKINS_PASSWORD=swordfish"  \
	-p 8090:8080 \
	blacklabelops/jenkins
~~~~

## Setting Executors

You can limit or extending the number of build processors. Define the environment
variable `SWARM_CLIENT_EXECUTORS`. Default is 4.

Example:

~~~~
$ docker run -d \
  --link jenkins_jenkins_1:jenkins \
	-e "SWARM_CLIENT_EXECUTORS=8" \
	blacklabelops/jenkins-swarm
~~~~

## Setting Swarm Labels

Labels are necessary when your swarm slaves run on different tools and JKDs. Define the environment
variable `SWARM_CLIENT_LABELS` for your swarm-clients labels. Afterwards you can
define which jobs should run on which labels.

Label are defined as a Whitespace-separated list to be assigned for this slave. Multiple options are allowed.

Example:

~~~~
$ docker run -d \
  --link jenkins:jenkins \
	-e "SWARM_CLIENT_LABELS=jdk8 java" \
	blacklabelops/jenkins-swarm
~~~~

## Using Jenkins With HTTPS

Yes, this all works perfectly with HTTPS. Your communication and artifacts are safe!

~~~~
$ docker run \
  --link jenkins:jenkins \
	-e "SWARM_MASTER_URL=https://jenkins:8080/" \
	blacklabelops/jenkins-swarm
~~~~

> SSL verification is disabled by default. So you do not to place certificates inside
the swarm client.

Wanna try? Here, use this command for a suitable master:

~~~~
$ docker run -d --name jenkins \
	-e "JENKINS_KEYSTORE_PASSWORD=swordfish" \
	-e "JENKINS_CERTIFICATE_DNAME=CN=SBleul,OU=Blacklabelops,O=blacklabelops.net,L=Munich,S=Bavaria,C=DE" \
	-p 8090:8080 \
	blacklabelops/jenkins
~~~~

> Master is available under https://docker-ip:8090

## Setting Java-VM Parameters

You can define start up parameters for the Java Virtual Machine, e.g. setting the memory size.

~~~~
$ docker run \
  --link jenkins:jenkins \
	-e "SWARM_VM_PARAMETERS=-Xmx512m -Xms256m" \
	blacklabelops/jenkins-swarm
~~~~

> You will have to use Java 8 parameters.

## Passing Slave Parameters

You can run the swarm slave solely with command line parameters!

Example:

~~~~
$ docker run \
    --link jenkins:jenkins \
	   blacklabelops/jenkins-swarm -master http://jenkins:8080
~~~~

> Will connect with linked master.

Example list parameters:
~~~~
$ docker run blacklabelops/jenkins-swarm -help
~~~~

> Lists jenkins-swarm plugin parameters.

Example with jvm parameters:

~~~~
$ docker run \
    --link jenkins:jenkins \
    -e "SWARM_VM_PARAMETERS=-Xmx512m -Xms256m" \
	   blacklabelops/jenkins-swarm -master http://jenkins:8080
~~~~

> Will connect with linked master.

## How To Extend This Image

Import the image inside your Dockerfile then just install all the tools you need. Start
the container with the parameters described in this readme.

Example:

~~~~
FROM blacklabelops/jenkins-swarm
MAINTAINER Your Name <youremail@yourhost.com>

# Need root to install tools via yum
USER root

# install toolset
RUN ...

# Switch back to container user
USER $CONTAINER_USER

CMD ["swarm"]
~~~~

## Container User & Permissions

> Note: First check out this project!

Simply: You can match user, user id, group and group id to any user and groups on your host machine!

Due to security considerations this image is not running in root mode! The default process user inside the container is `swarmslave` and the user's group is `swarmslave`. This project offers a simplified mechanism for user- and group-mapping. You can set the user, user id, group and group id during build time.

The process permissions are relevant when using volumes and mounted folders from the host machine. Jenkins need read and write permissions on the host machine for correct mounting of host volumes. You can set this during build time.

The following build arguments can be used:

* CONTAINER_USER: Set the user's name of the image user. (default: swarmslave)
* CONTAINER_GROUP: Set the group's name of the image user. (default: swarmslave)
* CONTAINER_UID: Set the user-id of the Jenkins process. (default: 1000)
* CONTAINER_GID: Set the group-id of the Jenkins process. (default: 1000)

Example:

~~~~
$ docker build \
    --build-arg CONTAINER_USER=swarm \
    --build-arg CONTAINER_GROUP=swarm \
    --build-arg CONTAINER_UID=2000 \
    --build-arg CONTAINER_GID=2000 \
    -t blacklabelops/jenkins-swarm .
~~~~

> The container will write and read files with user swarm with UID 2000 and group swarm with GID 2000.

Check It Out:

~~~~
$ docker run -it --rm blacklabelops/jenkins-swarm id
~~~~

> Prints its user details on console. `uid=2000(swarm) gid=2000(swarm) groups=2000(swarm)`

## Vagrant

> Note: First check out this project!

Vagrant is fabulous tool for pulling and spinning up virtual machines like docker with containers. I can configure my development and test environment and simply pull it online. And so can you! Install Vagrant and Virtualbox and spin it up. Change into the project folder and build the project on the spot!

~~~~
$ vagrant up
$ vagrant ssh
[vagrant@localhost ~]$ cd /vagrant
[vagrant@localhost ~]$ ./scripts/build.sh
~~~~

> Builds the container with standard settings.

Vagrant does not leave any docker artifacts on your beloved desktop and the vagrant image can simply be destroyed and repulled if anything goes wrong. Test my project to your heart's content!

First install:

* [Vagrant](https://www.vagrantup.com/)
* [Virtualbox](https://www.virtualbox.org/)

# Support

Leave a message and ask questions on Hipchat: [blacklabelops/hipchat](http://support.blacklabelops.com)

# References

* [Jenkins Homepage](http://jenkins-ci.org/)
* [Jenkins Swarm Plugin Homepage](https://wiki.jenkins-ci.org/display/JENKINS/Swarm+Plugin)
* [Docker Homepage](https://www.docker.com/)
* [Docker Compose](https://docs.docker.com/compose/)
* [Docker Userguide](https://docs.docker.com/userguide/)
* [Oracle Java8](https://java.com/de/download/)
