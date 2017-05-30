## postfix-python

Postfix with python support for blacklist utility.

### Variables

| Variable | Default | Description |
| -------- | ------- | ----------- |
| BLACKLIST_USER_SECRET | mysql-blacklist-user | MySQL cred secret name |
| CIDR_MIN_SIZE | 32 | size of netblock to blacklist |
| DB_HOST | dbhost | database host or IP |
| DB_NAME | blacklist | db name |
| DB_USER | blacklister | db user |
| HONEYPOT_ADDRS | honey@mydomain.com | comma-separated list of addresses |
| INBOUND_RELAY | "by mail.mydomain.com" | last inbound relay hop |
| SPAMLIMIT | 12 | any score above this will be quarantined |
| SPAMC_HOST | spamc | spamassassin host or IP |

### Secrets

| Secret | Description |
| ------ | ----------- |
| mysql-blacklist-user | username and password for MySQL db |
