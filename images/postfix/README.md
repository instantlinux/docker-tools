## postfix
[![](https://img.shields.io/docker/v/instantlinux/postfix?sort=date)](https://microbadger.com/images/instantlinux/postfix "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/postfix.svg)](https://microbadger.com/images/instantlinux/postfix "Image badge") ![](https://img.shields.io/badge/platform-amd64%20arm64%20arm%2Fv6%20arm%2Fv7-blue "Platform badge") [![](https://img.shields.io/badge/dockerfile-latest-blue)](https://gitlab.com/instantlinux/docker-tools/-/blob/master/images/postfix/Dockerfile "dockerfile")

The postfix daemon in a small Alpine Linux container, with client
support for separate spamassassin container. This is a layer which supports related image [postfix-python](https://hub.docker.com/r/instantlinux/postfix-python).

### Usage

Configuration is defined as files in a volume mounted as
/etc/postfix/postfix.d. Within that directory:

* Define your local settings as key = value pairs in postfix.cf; these
will be added/updated into main.cf (via postconf).

* Define aliases in aliases.

* Name any map files you need such as virtusertable with a _.map_ suffix (such as /etc/postfix/postfix.d/virtusertable.map).

* Define local users (if not using directory service) as users.sh.

See etc-example directory and kubernetes.yaml / docker-compose.yml.

### Variables

| Variable | Default | Description |
| -------- | ------- | ----------- |
| SASL_PASSWD_SECRET | postfix-sasl-passwd | name of secret for SASL map |
| TZ | UTC | time zone |

### Secrets

| Secret | Description |
| ------ | ----------- |
| postfix-sasl-passwd | mapped list of credentials for SASL destinations|

Look for sasl_passwd in [SASL_README.html](http://www.postfix.org/SASL_README.html#smtpd_sasl_security_options) for the format of the postfix-sasl-passwd secret.

Also, if you're using TLS, create a secret containing the SSL private key and
reference it in your smtpd_tls_key_file directive as shown in the example.

[![](https://images.microbadger.com/badges/license/instantlinux/postfix.svg)](https://microbadger.com/images/instantlinux/postfix "License badge") [![](https://img.shields.io/badge/code-vdukhovni%2Fpostfix-blue.svg)](https://github.com/vdukhovni/postfix "Code repo")
