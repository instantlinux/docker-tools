## squirrelmail

This is a heavily customized Dockerized version 1.4.21 of
squirrelmail, vintage 2003, with an address book (inspired by
the Palm Pilot) that I wrote as my learn-PHP exercise back in
the day.

### Usage
Set the variables as defined below, and run the docker-compose stack. The
service will be visible as http://host:port/squirrelmail.

### Variables

Variable | Default | Description
-------- | ------- | -----------
ATTACHMENT_DIR | /var/local/squirrelmail/attach/ | file attachments
BANNER_HEIGHT | 326 | Height of banner
BANNER_IMG | CambridgeBanner.jpg | splash-page banner image
BANNER_WIDTH | 433 | Width of banner
DATA_DIR | /var/local/squirrelmail/data/ | working dir
DB_HOST | db00 | db host
DB_NAME | squirrelmail |db name
DB_NAME_ADDR | contacts | db for addresses
DB_PASSWD_SECRET | squirrelmail-db-password | name of secret
DB_USER | sqmail | db username
DOMAIN | domain.com | default From domain
IMAP_AUTH_MECH | login | IMAP auth: login, plain, cram-md5, digest-md5
IMAP_PORT | 993 | dovecot imapd port
IMAP_SERVER | imap | hostname of imapd
IMAP_TLS | true | use TLS or not
MESSAGE_MOTD | "Remote WebMail Access" | 
ORGANIZATION | "The IT Crowd" | Organization
PROVIDER_NAME | "(Tech Support)" | Upper-right link text
PROVIDER_URI | http://squirrelmail.org/ | Upper-right link
PHP_POST_MAX_SIZE | 40M | Message max size
PHP_UPLOAD_MAX_FILESIZE | 32M | Upload max size
SMTP_AUTH_MECH | plain | SMTP auth: none or the above (see IMAP_AUTH)
SMTP_SMARTHOST | smtp | Outbound email relay hostname
SMTP_PORT | 587 | Port for sending emails (no auth)
SMTP_TLS | false | use TLS or not for SMTP
TZ | US/Pacific | time zone

### Secrets
| Name | Description |
| ---- | ----------- |
| squirrelmail-db-password | password to the MySQL database|