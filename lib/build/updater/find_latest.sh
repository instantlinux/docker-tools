#! /bin/sh
# This script generates a JSON blob detailing upstream dependencies by
# files in the entire monorepo, spelling out the newest-available
# version or tag.

# The companion script current_versions.sh generates a JSON blob
# with similar structure, spelling out what the version of artifacts
# previously published from this repo. It adds the path of at least one file
# within this repo that makes explicit reference to that version, so
# as to automate detection and response as newer versions are released
# by upstream publishers.

[ -z "$ALPINE_VERSION" ] && ALPINE_VERSION=3.24
[ -z "$UBUNTU_VERSION" ] && UBUNTU_VERSION=resolute
[ -z "$REPO_PATH" ]      && REPO_PATH=~/docker

# github allows 60 API calls per hour
NOW=$(date +%s)
curl -sS -D - -o /dev/null https://api.github.com/ | \
  grep -E "limit-(remaining|reset)" | awk '{ print $2; }' | {
    read -r REMAIN 
    read -r RESET
    REMAIN=$(echo $REMAIN | tr -d '\r\n')
    RESET=$(echo $RESET | tr -d '\r\n')
    WAIT=$(expr $RESET - $NOW + 2)
    if [ "$REMAIN" -lt 20 ]; then
      echo Hold on, GitHub API limit resets in $WAIT seconds >&2
      sleep $WAIT
    fi
}

echo "{"

docker run --rm -i alpine:$ALPINE_VERSION sh <<'EOF'
echo " " \"alpine-packages\": {
for IMG in data-sync ddclient dhcpd-dns-pxe dovecot ez-ipupdate git-dump \
    git-pull haproxy-keepalived mysqldump nagios nut-upsd openldap postfix \
    postfix-python proftpd rsyslogd samba samba-dc udp-nginx-proxy vsftpd; do
  case $IMG in
    data-sync)       PKG=unison;;
    dhcpd-dns-pxe)   PKG=kea;;
    git-dump)        PKG=git;;
    git-pull)        PKG=git;;
    haproxy-keepalived) PKG=haproxy;;
    mysqldump)       PKG=mariadb-client;;
    nut-upsd)        PKG=nut;;
    postfix-python)  PKG=postfix;;
    rsyslogd)        PKG=rsyslog;;
    udp-nginx-proxy) PKG=nginx;;
    *)               PKG=$IMG;;
  esac
  [ $IMG = data-sync ] || echo ,
  echo -n "   " \"$IMG\": {\"package\": \"$PKG\", \"version\": \"$( \
    apk policy $PKG|grep policy: -A1|tail -n1|grep -E -o [0-9a-z\.-]+)\"}
done
echo -e "\n  },"
EOF

docker run --rm -i ubuntu:$UBUNTU_VERSION sh <<'EOF'
echo " " \"ubuntu-packages\": {
apt-get update -qq >/dev/null
for IMG in blacklist spamassassin; do
  case $IMG in
    blacklist) PKG=rbldnsd;;
    *) PKG=$IMG;;
  esac
  VERSION=$(apt-cache madison $PKG | awk -F '|' '{print $2; }' | xargs)
  [ $IMG = blacklist ] && PKG=$(echo ${PKG%build1})
  [ $IMG = blacklist ] || echo ,
  echo -n "   " \"$IMG\": {\"package\": \"$PKG\", \"version\": \"$VERSION\"}
done
echo "\n  },"
EOF

echo " " \"python-packages\": {
for PKG in ansible GitPython pip PyGithub PyYAML weewx yadopt; do
  [ $PKG = ansible ] || echo ,
  echo -n "   " \"$PKG\": {\"version\": \"$( \
    curl -s https://pypi.org/pypi/$PKG/json | jq -r .info.version)\"}
done
echo "\n  },"

echo " " \"images\": {
cd $REPO_PATH
for IMG in alpine docker dxflrs/garage genebit/garage-webui \
    instantlinux/haproxy-keepalived quay.io/keycloak/keycloak mariadb \
    instantlinux/nagios instantlinux/nagiosql nginx instantlinux/nut-upsd \
    restic/rest-server; do
  case $IMG in
    alpine|docker|mariadb|nginx) REPO=library/$IMG;;
    *) REPO=$IMG
  esac
  if [ "$(echo $IMG | cut -d / -f 1)" = "ghcr.io" ]; then
    REPO=$(echo $IMG | cut -d / -f 2-)
    TAGS=$(docker run --rm regclient/regctl tag ls --limit 100 ${REPO})
  elif [ "$(echo $IMG | cut -d / -f 1)" = "quay.io" ]; then
    REPO=$(echo $IMG | cut -d / -f 2-)
    TAGS=$(curl -sL https://quay.io/api/v1/repository/$REPO/tag/ | \
      jq -r '.tags[].name')
  elif [ "$(echo $IMG | cut -d / -f 1)" = "registry.k8s.io" ]; then
    REPO=$(echo $IMG | cut -d / -f 2-)
    TAGS=$(curl -sL https://registry.k8s.io/v2/$REPO/tags/list | \
      jq -r '.manifest[].tag[]|select(endswith("amd64"))' | \
      cut -d - -f 1)
  else
    TAGS=$(curl -s https://hub.docker.com/v2/repositories/${REPO}/tags/?page_size=100 | \
      jq -r '.results[].name')
  fi
  TAG=$(echo $TAGS |tr " " "\n"| \
    grep -E '^[v]*[0-9]+\.[0-9]+(\.[0-9]+)?(\-([0-9]+(\.[0-9]+)))?$' | \
    sort -V | tail -n 1)
  [ $IMG = alpine ] || echo ,
  echo -n "   " \"$IMG\": {\"version\": \"$TAG\"}
done
echo "\n  },"

echo " " \"charts\": {
for CHART in alpine apache etcd gitea garage grafana guacamole headscale \
    immich jira nexus owntone radicale snappymail splunk synapse \
    vaultwarden wordpress wx-nginx; do
  SUFFIX=
  case $CHART in
    alpine)    IMG=library/alpine;;
    apache)    IMG=library/httpd;;
    etcd)      IMG=registry.k8s.io/etcd;;
    garage)    IMG=dxflrs/garage;;
    gitea)     IMG=$CHART/$CHART ; SUFFIX="-rootless";;
    grafana)   IMG=grafana/grafana-enterprise;;
    immich)    IMG=ghcr.io/immich-app/immich-server;;
    jira)      IMG=atlassian/jira-core;;  
    nexus)     IMG=sonatype/nexus3;;
    radicale)  IMG=ghcr.io/kozea/radicale;;
    snappymail) IMG=djmaze/snappymail;;
    synapse)   IMG=matrixdotorg/synapse;;
    vaultwarden) IMG=vaultwarden/server ; SUFFIX="-alpine";;
    wordpress) IMG=library/wordpress;;
    wx-nginx)  IMG=library/nginx ; SUFFIX="-alpine";;
    *)         IMG=$CHART/$CHART;;
  esac
  if [ "$(echo $IMG | cut -d / -f 1)" = "ghcr.io" ]; then
    TAGS=$(docker run --rm regclient/regctl tag ls --limit 100 ${IMG})
  elif [ "$(echo $IMG | cut -d / -f 1)" = "registry.k8s.io" ]; then
    REPO=$(echo $IMG | cut -d / -f 2)
    TAGS=$(curl -sL https://registry.k8s.io/v2/$REPO/tags/list | \
      jq -r '.manifest[].tag[]|select(endswith("amd64"))' | \
      cut -d - -f 1)
  else
    TAGS=$(curl -s https://hub.docker.com/v2/repositories/${IMG}/tags/?page_size=100 | \
      jq -r '.results[].name')
  fi
  TAG=$(echo $TAGS |tr " " "\n"| grep -E '^[v]*[0-9]+\.[0-9]+(\.[0-9]+)?$' | sort -V | tail -n 1)
  [ $CHART = alpine ] || echo ,
  echo -n "   " \"$CHART\": {\"repository\": \"$IMG\", \"version\": \"$TAG$SUFFIX\"}
done
echo "\n  },"

echo " " \"ansible-applied\": {
for ITEM in cni coredns docker-ce kubernetes smartmontools; do
  case $ITEM in
    cni)         ROLE=kubernetes; VERSION=$(apt-cache madison kubernetes-$ITEM | \
       awk -F '|' '{print $2; }' | xargs);;
    coredns)     ROLE=kubernetes; VERSION=$(curl -sL \
      https://registry.k8s.io/v2/$ITEM/$ITEM/tags/list | \
      jq -r '.manifest[].tag[]'| grep -E '^[v]*[0-9]+\.[0-9]+(\.[0-9]+)?' | \
      sort -V | tail -n 1);;
    docker-ce)   ROLE=docker_node; VERSION=$(apt-cache madison $ITEM | \
       grep -Ev "\-(rc|alpha)" | head -1 | awk -F '|' '{print $2; }' | xargs);;
    kubernetes)  ROLE=kubernetes; VERSION=$(curl -s \
      https://api.github.com/repos/kubernetes/$ITEM/releases | \
      jq -r '.[].tag_name' | grep -E '^[0-9]+\.[0-9]+(\.[0-9]+)?' | sort -V | tail -n 1);;
      # jq -r '.[].tag_name' | grep -Ev "\-(rc|alpha)" | sort -V | tail -n 1);;
    smartmontools) ROLE=monitoring_agent; VERSION=$(curl -s \
      https://api.github.com/repos/smartmontools/$ITEM/releases | \
      jq -r '.[].tag_name' | awk '{ sub(/^RELEASE_/, ""); print }' | tr _ . | \
      sort -V | tail -n 1);;
  esac
  [ $ITEM = cni ] || echo ,
  echo -n "   " \"$ITEM\": {\"role\": \"$ROLE\", \"version\": \"$VERSION\"}
done
echo "\n  },"

echo " " \"github-imports\": {
for SOURCE in cert-manager/cert-manager Mirantis/cri-dockerd envoyproxy/gateway \
    flannel-io/flannel helm/helm kubernetes/node-local-dns \
    kubernetes/kube-state-metrics getsops/sops aquasecurity/trivy; do
  case $SOURCE in
    kubernetes/node-local-dns) REPO=kubernetes/kubernetes;;
    *) REPO=$SOURCE;;
  esac
  VERSION=$(curl -s https://api.github.com/repos/$REPO/releases | \
      jq -r '.[].tag_name' | grep -Ev "\-(rc|alpha)" | sort -V | tail -n 1)
  [ $SOURCE = cert-manager/cert-manager ] || echo ,
  echo -n "   " \"$SOURCE\": {\"version\": \"$VERSION\"}
done
echo "\n  },"

echo " " \"manual-checks\": {
echo "   " \"mariadb-galera\": {\"image\": \"mariadb\", \"url\": \"https://hub.docker.com/_/mariadb/tags\"},
echo "   " \"mythtv-backend\": {\"package\": \"mythtv\", \"url\": \"https://blueprints.launchpad.net/~mythbuntu/+archive/ubuntu/36\"},
echo "   " \"nagiosql\": {\"download\": \"nagiosql\", \"url\": \"https://sourceforge.net/projects/nagiosql/files/\"}
echo "  }"
echo "}"
