#! /bin/bash
set -e

REF=/usr/share/jenkins/ref/plugins
mkdir -p $REF
umask 022

echo "downloading plugins specified in plugins.txt"
while read spec || [ -n "$spec" ]; do
    plugin=(${spec//:/ });
    [[ ${plugin[0]} =~ ^# ]] && continue
    [[ ${plugin[0]} =~ ^\s*$ ]] && continue
    [[ -z ${plugin[1]} ]] && plugin[1]="latest"
    echo " -- ${plugin[0]}:`basename ${plugin[1]}`"
    curl -sSL -f ${JENKINS_DOWNLOADS}/plugins/${plugin[0]}/${plugin[1]}/${plugin[0]}.hpi -o $REF/${plugin[0]}.jpi
    unzip -qqt $REF/${plugin[0]}.jpi
done  < $1
