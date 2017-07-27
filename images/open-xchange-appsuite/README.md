## OX App Suite docker image

Private-cloud online documents portal for spreadsheet, word-processing, presentations,email, calendar, and cloud file storage.

This image is based on [Open-Xchange installation for debian 8.0](http://oxpedia.org/wiki/index.php?title=AppSuite:Open-Xchange_Installation_Guide_for_Debian_8.0).

For more details, see the vendor's site [OX App Suite](http://open-xchange.com/en/home).

### Usage

See the docker-compose.yml here; set up the variables and secrets as defined below, and invoke the stack under Docker Swarm.

        echo -n mysecret1 | docker secret create ox-admin-password -
        echo -n mysecret2 | docker secret create ox-db-password -
        echo -n mysecret3 | docker secret create ox-master-password -

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


UI is available at http://yourhost/appsuite. One setting you will probably want to change is com.openexchange.capability.presentation in file etc/documents.properties: Open Xchange has the Text word-processor and Spreadsheet utilities enabled by default, but Presentation remains disabled until you activate this setting.

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

### License

[GPLv2](https://www.open-xchange.com//fileadmin/user_upload/open-xchange/document/license/GNU_General_Public_License.pdf)


