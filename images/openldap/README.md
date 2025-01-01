## openldap
[![](https://img.shields.io/docker/v/instantlinux/openldap?sort=date)](https://hub.docker.com/r/instantlinux/openldap/tags "Version badge") [![](https://img.shields.io/docker/image-size/instantlinux/openldap?sort=date)](https://github.com/instantlinux/docker-tools/tree/main/images/openldap "Image badge") ![](https://img.shields.io/badge/platform-amd64%20arm64%20arm%2Fv6%20arm%2Fv7-blue "Platform badge") [![](https://img.shields.io/badge/dockerfile-latest-blue)](https://gitlab.com/instantlinux/docker-tools/-/blob/main/images/openldap/Dockerfile "dockerfile")

This is OpenLDAP in a tiny alpine container, with simple setup. All features and capabilities are supported.

Why this new image (in 2022), when there are others? The dinkel and osixia images fell out of maintenance, so the only current maintained alternative is the larger / more complex / single-platform bitnami.

### Usage

Set environment variables as shown below, and mount a blank storage volume as `/var/lib/openldap/openldap-data`. Optionally, put your users and groups into ldif format (see [example](https://github.com/instantlinux/docker-tools/blob/main/images/openldap/example-users.ldif)) and mount them as `/etc/openldap/prepopulate`, and/or add TLS certifates under `/etc/ssl/openldap`.

Example kubernetes and docker-compose resource definition files are provided here along with a helm chart. This repo has complete instructions for
[building a kubernetes cluster](https://github.com/instantlinux/docker-tools/blob/main/k8s/README.md) where you can launch with [helm](https://github.com/instantlinux/docker-tools/tree/main/images/openldap/helm) using _make_ and customizing [Makefile.vars](https://github.com/instantlinux/docker-tools/blob/main/k8s/Makefile.vars) after cloning this repo:
~~~
git clone https://github.com/instantlinux/docker-tools.git
cd docker-tools/k8s
make openldap
~~~

### Variables

| Variable | Default | Description |
| -------- | ------- | ----------- |
| SLAPD_DN_ATTR | uid | Attribute of user dn (usually `cn` or `uid`) |
| SLAPD_FQDN | example.com | |
| SLAPD_LOG_LEVEL | Config,Stats | See [loglevel keywords](https://www.openldap.org/doc/admin24/slapdconfig.html) |
| SLAPD_ORGANIZATION | Example | |
| SLAPD_OU | ou=users, | Org-unit component of DN |
| SLAPD_PWD_ATTRIBUTE | userPassword | Attribute of hashed password |
| SLAPD_PWD_CHECK_QUALITY | 2 | Password-modify enforcement option 0-2 |
| SLAPD_PWD_FAILURE_COUNT_INTERVAL | 1200 | Reset failures [20 min] |
| SLAPD_PWD_LOCKOUT_DURATION | 1200 | Clear lockout [20 min] |
| SLAPD_PWD_MAX_FAILURE | 5 | Maximum attempts before lockout |
| SLAPD_PWD_MIN_LENGTH | 8 | Password-modify minimum length |
| SLAPD_ROOTDN | cn=admin,dc=(suffix)  | Admin user's DN |
| SLAPD_ROOTPW |  | Plain-text admin password |
| SLAPD_ROOTPW_HASH |  | Hashed admin password |
| SLAPD_ROOTPW_SECRETNAME | openldap-ro-password | Name of secret to hold pw |
| SLAPD_SUFFIX | (based on `SLAPD_FQDN`) | Suffix of DN |
| SLAPD_ULIMIT | 2048 | maximum file size |
| SLAPD_USERPW_SECRETNAME | openldap-user-passwords | Name of secret to hold pws |

If overriding default root DN, it should be specified in the form `cn=admin,dc=example,dc=com`.

The root password must be specified in one of three ways:

* `SLAPD_ROOTPW` - plain text value, only for testing
* `SLAPD_ROOTPW_HASH` - encrypted value starting with `{PBKDF2-SHA512}`
* `openldap-ro-password` secret - most secure place to store the hash

You will want to override values for `SLAPD_FQDN` and `SLAPD_ORGANIZATION`. All the other default values will work for many typical use-cases.

User passwords are normally initialized by the administrator using `ldappasswd`, and from then on updated by the user (through the same tool or protocol). With this image, you can also define user passwords by providing their (hashed) values via a secret. Don't use `ldappasswd` to update passwords that are provided with the latter method: use it to generate a new hashed value and update the secret.
### Volumes

Mount these path names to persistent storage; all are optional.

Path | Description
---- | -----------
/etc/openldap/prepopulate | Zero or more .ldif files to load upon startup
/var/lib/openldap/openldap-data | Persistent storage for ldap database
/etc/ssl/openldap | TLS/SSL certificate

### Secrets

Secret | Description
------ | -----------
openldap-rootpw | Hashed password (key name openldap-rootpw-hash)
openldap-ssl | Certificate (cacert.pem, tls.crt, tls.key)
openldap-user-passwords | Hashed passwords (in _user: {PBK...} hash_ form)

### Contributing

If you want to make improvements to this image, see [CONTRIBUTING](https://github.com/instantlinux/docker-tools/blob/main/CONTRIBUTING.md).

[![](https://img.shields.io/badge/license-OpenLDAP-red.svg)](https://git.openldap.org/openldap/openldap/-/blob/master/LICENSE "License badge") [![](https://img.shields.io/badge/code-openldap%2Fopenldap-blue.svg)](https://git.openldap.org/openldap/openldap "Code repo")
