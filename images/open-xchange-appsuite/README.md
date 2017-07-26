## OX App Suite docker image

Online documents portal for spreadhsheet, word-processing, email, calendar cloud file storage.

This image is based on [Open-Xchange installation for debian 8.0](http://oxpedia.org/wiki/index.php?title=AppSuite:Open-Xchange_Installation_Guide_for_Debian_8.0).

For more details, see the vendor's site [OX App Suite](http://open-xchange.com/en/home)

### Usage

See the docker-compose.yml here; set up the variables and secrets as defined below, and invoke the stack under Docker Swarm.

Once the container is launched, context-admin can register new users:

    docker exec <container_name> /opt/open-xchange/sbin/createuser \
      -A oxadmin -c 1 -d jennifer_wu -e jwu@domain.com \
      -g Jennifer -s Wu -l en_US -p password -u jwu -P <admin password>

UI is available at http://yourhost/appsuite.

### Variables

| Variable | Default | Description |
| -------- | ------- | ----------- |
| OX_ADMIN_MASTER_LOGIN | oxadminmaster | system admin login |
| OX_ADMIN_MASTER_PASSWORD | admin_master_password | system admin password |
| OX_CONTEXT_ADMIN_LOGIN | oxadmin | context admin login |
| OX_CONTEXT_ADMIN_PASSWORD | oxadmin |context admin password |
| OX_CONTEXT_ADMIN_EMAIL | admin@example.com| context admin email |
| OX_CONTEXT_ID | 1 | context id (number) |
| OX_SERVER_NAME | oxserver | server name |
| OX_SERVER_MEMORY | 1024 | server memory limit (MB) |

### Secrets

| ox-db-password | configuration database password |
| ox-master-password |system admin password |
| ox-admin-password |context admin password |

### License

[GPLv2](https://www.open-xchange.com//fileadmin/user_upload/open-xchange/document/license/GNU_General_Public_License.pdf)


