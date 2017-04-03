FROM tomcat:8-jre8

MAINTAINER Matthias Grüter <matthias@grueter.name>

ENV ARTIFACTORY_VERSION 5.2.0
ENV ARTIFACTORY_SHA256 6d6323f06b53d2760d25c0afab1b42bb1fed9adca48b6931b07f0df33cb7a38b

# Disable Tomcat's manager application.
RUN rm -rf webapps/*

RUN \
  echo $ARTIFACTORY_SHA256 artifactory.zip > artifactory.zip.sha256 && \
  curl -L -o artifactory.zip https://bintray.com/jfrog/artifactory/download_file?file_path=jfrog-artifactory-oss-${ARTIFACTORY_VERSION}.zip && \
  sha256sum -c artifactory.zip.sha256 && \
  unzip -j artifactory.zip "artifactory-*/webapps/artifactory.war" -d webapps && \
  rm artifactory.zip

# Expose tomcat runtime options through the RUNTIME_OPTS environment variable.
#   Example to set the JVM's max heap size to 256MB use the flag
#   '-e RUNTIME_OPTS="-Xmx256m"' when starting a container.
RUN echo 'export CATALINA_OPTS="$RUNTIME_OPTS"' > bin/setenv.sh

RUN mkdir -p /artifactory
ENV ARTIFACTORY_HOME /artifactory

VOLUME /artifactory/data
VOLUME /artifactory/logs
VOLUME /artifactory/backup
WORKDIR /artifactory
