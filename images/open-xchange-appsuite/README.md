## OX App Suite docker image
[![](https://images.microbadger.com/badges/version/instantlinux/open-xchange-appsuite.svg)](https://microbadger.com/images/instantlinux/open-xchange-appsuite "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/open-xchange-appsuite.svg)](https://microbadger.com/images/instantlinux/open-xchange-appsuite "Image badge") [![](https://images.microbadger.com/badges/commit/instantlinux/open-xchange-appsuite.svg)](https://microbadger.com/images/instantlinux/open-xchange-appsuite "Commit badge")

Private-cloud online documents portal for spreadsheet, word-processing, presentations,email, calendar, and cloud file storage.

This image is based on [Open-Xchange installation for debian 8.0](http://oxpedia.org/wiki/index.php?title=AppSuite:Open-Xchange_Installation_Guide_for_Debian_8.0).

For more details, see the vendor's site [OX App Suite](http://open-xchange.com/en/home).

### Usage

See the kubernetes or docker-compose.yml here; make sure you have a compatible database running first (the [mariadb-galera](https://cloud.docker.com/repository/docker/instantlinux/mariadb-galera) service is one option), set up the variables and secrets as defined below, and invoke the resource.

kubernetes:
```
    kubectl create secret generic --from-literal=ox-admin-password=mysecret1 \
      ox-admin-password
    kubectl create secret generic --from-literal=ox-db-password=mysecret1 \
      ox-db-password
    kubectl create secret generic --from-literal=ox-master-password=mysecret1 \
      ox-master-password
```

docker swarm:
```
    echo -n mysecret1 | docker secret create ox-admin-password -
    echo -n mysecret2 | docker secret create ox-db-password -
    echo -n mysecret3 | docker secret create ox-master-password -
```
Create database and grant access:

        mysql> CREATE DATABASE oxdata;
        mysql> GRANT ALL PRIVILEGES ON `oxdata`.* TO 'openxchange'@'%'
               IDENTIFIED BY 'mysecret2';
        mysql> GRANT ALL PRIVILEGES ON `oxdatabase_5`.* TO 'openxchange'@'%'
               IDENTIFIED BY 'mysecret2';

Change the mounted volume /ox/etc to allow read/write; it is populated
with default settings at first launch. Afterward, you can set it to
ro/read-only as in the example docker-compose.yml (and manage its
contents with your favorite source-code tool such as git; subsequent restarts
copy these files into /opt/open-xchange/etc).

Once the container is launched, context-admin can register new users:

        docker exec <container_name> /opt/open-xchange/sbin/createuser \
          -A oxadmin -c 1 -d jennifer_wu -e jwu@domain.com \
          -g Jennifer -s Wu -l en_US -p password -u jwu -P <admin password>

UI is available at http://yourhost/appsuite. There are at least two settings you will probably want to change:

* com.openexchange.capability.presentation in file etc/documents.properties: Open Xchange has the Text word-processor and Spreadsheet utilities enabled by default, but Presentation remains disabled until you activate this setting.
* com.openexchange.hazelcast.group.password in file hazelcast.properties: this has a widely-known default value; change it to a random string.

This repo has complete instructions for
[building a kubernetes cluster](https://github.com/instantlinux/docker-tools/blob/master/k8s/README.md) where you can deploy [kubernetes.yaml](https://github.com/instantlinux/docker-tools/blob/master/images/open-xchange-appsuite/kubernetes.yaml) with the Makefile or:
~~~
cat kubernetes.yaml | envsubst | kubectl apply -f -
~~~

### Variables

| Variable | Default | Description |
| -------- | ------- | ----------- |
| OX_ADMIN_MASTER_LOGIN | oxadminmaster | system admin login |
| OX_CONFIG_DB_HOST | db00 | MySQL database hostname |
| OX_CONFIG_DB_NAME | oxdata | database name |
| OX_CONFIG_DB_USER | openxchange | database username |
| OX_CONTEXT_ADMIN_LOGIN | oxadmin | context admin login |
| OX_CONTEXT_ADMIN_EMAIL | admin@domain.com| context admin email |
| OX_CONTEXT_ID | 1 | context id (number) |
| OX_SERVER_NAME | oxserver | server name |
| OX_SERVER_MEMORY | 2048 | server memory limit (MB) |

### Secrets

| Secret | Description |
| ------ | ----------- |
| ox-admin-password |context admin password |
| ox-db-password | configuration database password |
| ox-master-password |system admin password |

[![](https://images.microbadger.com/badges/license/instantlinux/open-xchange-appsuite.svg)](https://microbadger.com/images/instantlinux/open-xchange-appsuite "License badge") [![](https://img.shields.io/badge/code-open_xchange%2Fscm-blue.svg)](https://code.open-xchange.com "Code repo")
