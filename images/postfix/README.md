## postfix
[![](https://images.microbadger.com/badges/version/instantlinux/postfix.svg)](https://microbadger.com/images/instantlinux/postfix "Version badge") [![](https://images.microbadger.com/badges/image/instantlinux/postfix.svg)](https://microbadger.com/images/instantlinux/postfix "Image badge") [![](https://images.microbadger.com/badges/commit/instantlinux/postfix.svg)](https://microbadger.com/images/instantlinux/postfix "Commit badge")

The postfix daemon in a small Alpine Linux container, with client
support for separate spamassassin container.

### Usage

Configuration is defined as files in a volume mounted as
/etc/postfix/postfix.d. Within that directory:

* Define your local settings as key = value pairs in postfix.cf; these
will be added/updated into main.cf (via postconf).

* Define aliases in aliases.

* Define any map files such as virtusertable as *.map.

* Define local users (if not using directory service) as users.sh.

See etc-example directory and kubernetes.yaml / docker-compose.yml. This repo has complete instructions for
[building a kubernetes cluster](https://github.com/instantlinux/docker-tools/blob/master/k8s/README.md) where you can deploy [kubernetes.yaml](kubernetes.yaml) with the Makefile or:
~~~
cat kubernetes.yaml | envsubst | kubectl apply -f -
~~~

### Variables

| Variable | Default | Description |
| -------- | ------- | ----------- |
| SASL_PASSWD_SECRET | postfix-sasl-passwd | name of secret for SASL map |
| TZ | UTC | time zone |

### Secrets

| Secret | Description |
| ------ | ----------- |
| postfix-sasl-passwd | mapped list of credentials for SASL destinations|

Also, if you're using TLS, create a secret containing the SSL private key and
reference it in your smtpd_tls_key_file directive as shown in the example.

[![](https://images.microbadger.com/badges/license/instantlinux/postfix.svg)](https://microbadger.com/images/instantlinux/postfix "License badge")
