#! /bin/sh
# current_inventory.sh
#
#   created 2-oct-2026 by richb@instantlinux.net
#
#   produces a manifest of versions of objects this repo depends on
#
#   TODO - pythonize

[ -z "$REPO_PATH" ] && REPO_PATH=~/docker
echo "{"

cd $REPO_PATH/images
echo " " \"alpine-packages\": {
for IMG in $(echo *); do
  if ! grep -q "FROM alpine" $IMG/Dockerfile; then
    continue
  fi
  [ -f $IMG/hooks/add_tags ] || continue

  PATHS=\"images/$IMG/Dockerfile\"
  case $IMG in
    data-sync)       PKG=unison;;
    dhcpd-dns-pxe)   PKG=kea;;
    git-dump)        PKG=git;;
    git-pull)        PKG=git;;
    haproxy-keepalived) PKG=haproxy;;
    mysqldump)       PKG=mariadb-client;;
    nut-upsd)        PKG=nut; PATHS="$PATHS, \"services/Makefile\"";;
    postfix)         PATHS="$PATHS, \"images/postfix-python/Dockerfile\", \
        \"images/postfix-python/helm/Chart.yaml\""; PKG=$IMG;;
    postfix-python)  PKG=postfix;;
    rsyslogd)        PKG=rsyslog;;
    udp-nginx-proxy) PKG=nginx;;
    weewx)           continue;;     # built from pypi not alpine-pkgs
    *)               PKG=$IMG;;
  esac
  cd $IMG
  [ $IMG = data-sync ] || echo ,
  [ -f ./helm/Chart.yaml ] && PATHS="$PATHS, \"images/$IMG/helm/Chart.yaml\""
  echo -n "   " \"$IMG\": {\"package\": \"$PKG\", \"version\": \"$( \
    ./hooks/add_tags)\", \"paths\": [$PATHS]}
  cd ..
done
echo "\n  },"

echo " " \"ubuntu-packages\": {
for IMG in $(echo *); do
  if ! grep -qE "FROM (debian|ubuntu)" $IMG/Dockerfile; then
    continue
  fi

  case $IMG in
    blacklist) PKG=rbldnsd;;
    mythtv-backend) PKG=mythtv;;
    *) PKG=$IMG;;
  esac
  cd $IMG
  [ $IMG = blacklist ] || echo ,
  echo -n "   " \"$IMG\": {\"package\": \"$PKG\", \"version\": \"$( \
    ./hooks/add_tags)\", \"paths\": [\"images/$IMG/Dockerfile\"]}
  cd ..
done
echo "\n  },"

echo " " \"python-packages\": {
cd $REPO_PATH
for PKG in ansible GitPython pip PyGithub PyYAML weewx yadopt; do
  MATCH=$PKG
  case $PKG in
    ansible | pip)
      FILE=ansible/requirements.txt;;
    GitPython | PyGithub | PyYAML | yadopt)
      FILE=lib/build/updater/requirements.txt;;
    weewx)
      FILE=images/weewx/Dockerfile; MATCH=WEEWX_VERSION;;
  esac
  [ $PKG = ansible ] || echo ,
  echo -n "   " \"$PKG\": {\"version\": \"$( \
   grep -E ${MATCH}[=]+ $FILE | grep -Eo [0-9.-]+)\", \
   \"paths\": [\"$FILE\"]}
done
echo "\n  },"

echo " " \"images\": {
cd $REPO_PATH
for IMAGE in alpine docker dxflrs/garage genebit/garage-webui \
    guacamole/guacd guacamole/guacamole instantlinux/haproxy-keepalived \
    quay.io/keycloak/keycloak mariadb instantlinux/nagios \
    instantlinux/nagiosql nginx prom/alertmanager prom/prometheus \
    ghcr.io/immich-app/immich-machine-learning restic/rest-server \
    awesometechnologies/synapse-admin vectorim/element-web aquasec/trivy \
    valkey/valkey; do
  FILE=services/Makefile
  unset FILES
  case $IMAGE in
    alpine)
      FILES=$(grep "FROM alpine" images/*/Dockerfile | cut -d : -f 1| \
        awk '{ print "\""$1"\""; }'| paste -sd,)
      FIRST=$(echo $FILES | cut -d '"' -f 2)
      TAG=$(grep "FROM alpine" $FIRST | grep -oE "[1-9]+\.[0-9]+(\.[0-9])*");;
    docker)
      FILES='".image-gitlab-ci.yml", ".gitlab-ci.yml"'
      TAG=$(grep ^image: .gitlab-ci.yml | grep -oE "[1-9]+\.[0-9]+(\.[0-9])*");;
    dxflrs/garage)
      TAG=$(grep VERSION_GARAGE $FILE | awk '{ print $4; }');;
    genebit/garage-webui)
      TAG=$(grep VERSION_GAR_WEBUI $FILE | awk '{ print $4; }');;
    instantlinux/haproxy-keepalived)
      TAG=$(grep VERSION_HA_KA $FILE | awk '{ print $4; }');;
    quay.io/keycloak/keycloak)
      TAG=$(grep VERSION_KEYCLOAK $FILE | awk '{ print $4; }');;
    mariadb)
      TAG=$(grep VERSION_KC_DB $FILE | awk '{ print $4; }');;
    instantlinux/nagios)
      TAG=$(grep -m 1 VERSION_NAGIOS $FILE | awk '{ print $4; }');;
    instantlinux/nagiosql)
      TAG=$(grep VERSION_NAGIOSQL $FILE | awk '{ print $4; }');;
    nginx)
      TAG=$(grep VERSION_NGINX $FILE | awk '{ print $4; }');;
    restic/rest-server)
      TAG=$(grep VERSION_RESTIC $FILE | awk '{ print $4; }');;
    aquasec/trivy) FILE=.image-gitlab-ci.yml
      TAG=$(grep -m 1 -i TRIVY_VERSION: $FILE | awk '{ print $2; }');;
    # Images for subcharts
    guacamole/guacd | guacamole/guacamole | ghcr.io/tale/headplane | \
        ghcr.io/immich-app/immich-machine-learning | prom/alertmanager | \
        prom/prometheus | awesometechnologies/synapse-admin | \
	vectorim/element-web | valkey/valkey)
      case $(echo $IMAGE | cut -d / -f 1) in
        awesometechnologies | vectorim) CHART=synapse;;
        prom) CHART=grafana;;
	ghcr.io)
          if [ "$IMAGE" = "ghcr.io/tale/headplane" ]; then
            CHART=headscale
	  elif [ "$IMAGE" = "ghcr.io/immich-app/immich-machine-learning" ]; then
            CHART=immich
          fi;;
        valkey) CHART=immich;;
        *) CHART=$(echo $IMAGE | cut -d / -f 1);;
      esac
      case $(echo $IMAGE | rev | cut -d / -f 1 | rev) in
        element-web) SUBCHART=element;;
        guacamole) SUBCHART=guacamole-server;;
	immich-machine-learning) SUBCHART=ml;;
        synapse-admin) SUBCHART=admin;;
	*) SUBCHART=$(echo $IMAGE | cut -d / -f 2);;
      esac
      FILE=k8s/helm/$CHART/values.yaml
      TAG=$(grep -A 5 ^${SUBCHART}: $FILE | grep tag: | \
        awk '{ print $2; }');;
  esac
  [ -z "${FILES+defined}" ] && FILES=\"$FILE\"
  [ $IMAGE = alpine ] || echo ,
  echo -n "   " \"$IMAGE\": {\"version\": \"$TAG\", \"paths\": [$FILES]}
done
echo "\n  },"

echo " " \"charts\": {
cd $REPO_PATH/k8s/helm
for CHART in $(echo *); do
  [ -f $CHART/values.yaml ] || continue
  REPO=$(grep -E '^(\s+)repository:' ./$CHART/values.yaml | awk '{ print $2; }')
  [ -z "$REPO" ] && continue
  [ $(echo $REPO | cut -d / -f 1) = "instantlinux" ] && continue
  TAG=$(grep ^appVersion ./$CHART/Chart.yaml | awk '{ gsub(/"/, ""); print $2; }')
  PATHS=\"k8s/helm/$CHART/Chart.yaml\"
  case $CHART in
    apache|grafana|headscale|immich|jira|nexus|owntone|radicale|snappymail| \
    splunk|synapse)
      PATHS="$PATHS, \"README.md\"";;
  esac
  [ $CHART = apache ] || echo ,
  echo -n "   " \"$CHART\": {\"repository\": \"$REPO\", \"version\": \"$TAG\", \
    \"paths\": [$PATHS]}
done
echo "\n  },"

cd $REPO_PATH/ansible/roles
echo " " \"ansible-applied\": {
for ITEM in cni coredns docker-ce kubernetes smartmontools; do
  case $ITEM in
    cni)         ROLE=kubernetes; VERSION=$(grep cni_version: \
      $ROLE/defaults/main.yml | awk '{ print $2; }');;
    coredns)     ROLE=kubernetes; VERSION=$(grep coredns_version: \
      $ROLE/defaults/main.yml | awk '{ print $2; }');;
    docker-ce)   ROLE=docker_node; VERSION=$(grep package_ver: \
      $ROLE/defaults/main.yml | awk '{ print $2; }');;
    kubernetes)  ROLE=kubernetes; VERSION=$(grep -m 1 '^[ ]*version:' \
      $ROLE/defaults/main.yml | awk '{ print $2; }');;
    smartmontools) ROLE=monitoring_agent; \
      VERSION=$(grep -A 1 -m 1 smartmon_download: \
      $ROLE/defaults/main.yml | tail -1 | awk '{ gsub(/"/, ""); print $2; }');;
  esac
  [ $ITEM = cni ] || echo ,
  echo -n "   " \"$ITEM\": {\"role\": \"$ROLE\", \"version\": \"$VERSION\", \
    \"paths\": [\"ansible/roles/$ROLE/defaults/main.yml\"]}
done	
echo "\n  },"

echo " " \"github-imports\": {
cd $REPO_PATH
for SOURCE in cert-manager/cert-manager Mirantis/cri-dockerd envoyproxy/gateway \
    flannel-io/flannel helm/helm kubernetes/kube-state-metrics \
    kubernetes/node-local-dns getsops/sops chaunceygardiner/weewx-airlink; do
  ITEM=$(echo $SOURCE | cut -d / -f 2 | tr '-' _)
  FILE=k8s/Makefile.versions
  case $ITEM in
    cri_dockerd) FILE=ansible/roles/kubernetes/defaults/main.yml
       VERSION=$(grep -A 1 cri_dockerd: $FILE | \
       tail -1 | awk '{ print $2; }');;
    weewx_airlink) FILE=images/weewx/Dockerfile
       VERSION=$(grep "^ARG AIRLINK_VERSION" $FILE | cut -d = -f 2);;
    *) VERSION=$(grep -i VERSION_$ITEM $FILE | awk '{ print $4; }');;
  esac
  [ $SOURCE = cert-manager/cert-manager ] || echo ,
  echo -n "   " \"$SOURCE\": {\"version\": \"$VERSION\", \"paths\": \
    [\"$FILE\"]}
done
echo "\n  }",

echo " " \"manual-checks\": {
cd $REPO_PATH/images
for IMG in mariadb-galera nagiosql; do
  cd $IMG
  FILE=images/$IMG/Dockerfile
  TAG=$(./hooks/add_tags)
  case $IMG in
    mariadb-galera) IMAGE=mariadb;;
    nagiosql) IMAGE=nagiosql;;
  esac
  [ $IMG = mariadb-galera ] || echo ,
  echo -n "   " \"$IMG\": {\"image\": \"$IMAGE\", \"version\": \
    \"$TAG\", \"paths\": [\"$FILE\", \"images/$IMG/helm/Chart.yaml\"]}
  cd ..
done
echo "\n  }"

echo "}"
