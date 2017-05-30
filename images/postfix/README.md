## postfix

The postfix daemon in a small Alpine Linux container, with client
support for separate spamassassin container.

### Usage

Configuration is defined as files in a volume mounted as
/etc/postfix/postfix.d. Within that directory:

* Define your local settings as key = value pairs in postfix.cf; these
will be added/updated into main.cf (via postconf).

* Define aliases in aliases.

* Define any map files such as virtusertable as *.map.

See etc-example directory and docker-compose.yml.

### Variables

| Variable | Default | Description |
| -------- | ------- | ----------- |
| SASL_PASSWD_SECRET | postfix-sasl-passwd | name of secret for SASL map |
| TZ | US/Pacific | time zone |

### Secrets

| Secret | Description |
| ------ | ----------- |
| postfix-sasl-passwd | mapped list of credentials for SASL destinations|

Also, if you're using TLS, create a secret containing the SSL private key and
reference it in your smtpd_tls_key_file directive as shown in the example.
