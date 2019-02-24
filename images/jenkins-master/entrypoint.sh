#!/bin/bash -e

if [ ! -s /etc/timezone ] && [ ! -z "$TZ" ]; then
  # At first startup, set timezone
  cat /usr/share/zoneinfo/$TZ >/etc/localtime
  echo $TZ >/etc/timezone
fi
if [ -e /run/secrets/$JENKINS_ADMIN_SECRET ]; then
  export JENKINS_ADMIN_PASS=$(cat /run/secrets/$JENKINS_ADMIN_SECRET)
fi

# Process templates in /usr/share/jenkins/ref
cd $JENKINS_REF
for file in $(find . -name '*.j2'); do
  dest=$JENKINS_HOME/$(echo $file | sed -e 's/[.]j2$//')
  [ -f $dest ] && continue
  sed -e "s+{{ ARTIFACTORY_PASS }}+$ARTIFACTORY_PASS+" \
      -e "s+{{ ARTIFACTORY_URI }}+$ARTIFACTORY_URI+" \
      -e "s+{{ ARTIFACTORY_USER }}+$ARTIFACTORY_USER+" \
      -e "s+{{ JENKINS_LIBRARY }}+$JENKINS_LIBRARY+" \
      -e "s+{{ SMTP_SMARTHOST }}+$SMTP_SMARTHOST+" \
    $file > $dest
done

# Copy files from $JENKINS_REF into $JENKINS_HOME that aren't already there
# This is a reference config, to enable UI to make changes that persist
# beyond container restart.
copy_reference_file() {
  file=${1%/} 
  rel=${file:23}
  dir=$(dirname ${file})
  if [ ! -e $JENKINS_HOME/${rel} ]; then
    echo " $file: copied" >> $COPY_REFERENCE_FILE_LOG
    mkdir -p $JENKINS_HOME/${dir:23}
    cp -r $JENKINS_REF/${rel} $JENKINS_HOME/${rel}
    # pin plugins on initial copy
    #   TODO what's this??
    #   [ ${rel} == plugins/*.jpi ] &&
    touch $JENKINS_HOME/${rel}.pinned
  else
    echo " $file skipped" >> $COPY_REFERENCE_FILE_LOG
  fi
}

export -f copy_reference_file
echo "--- Copying files at $(date)" >> $COPY_REFERENCE_FILE_LOG
find $JENKINS_REF/ -type f -exec bash -c "copy_reference_file '{}'" \;

# if first argument is `--`: start jenkins with launcher args
if [ $# -lt 1 ] || [ "$1" == "--"* ]; then
  exec java $JAVA_OPTS -jar /usr/share/jenkins/jenkins.war $JENKINS_OPTS "$@"
else
  exec "$@"
fi
