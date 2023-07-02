#!/usr/bin/env python
"""Gencerts for docker

created 20-apr-2017 by richb@instantinux.net

Usage:
  gencerts.py [--ask-passphrase] [--ca-file=FILE] [--ca-subject=STR]
              [--client-name=FQDN]... [--client-ip=IP]...
              [--config-file=FILE] [--cn-client=STR]
              [--cn-root=STR]
              [--days=N] [--directory=PATH]
              [--host-name=FQDN]...
              [--key-size=N] [--port=N]
              [--subj-city=STR] [--subj-country=STR] [--subj-org=STR]
              [--subj-ou=STR] [--subj-state=STR]
              [--no-encrypted-ca] [-v]...
  gencerts.py (-h | --help)

Options:
  --ask-passphrase    Ask for passphrase
  --ca-file=FILE      CA root cert file prefix [default: ca]
  --ca-subject=STR    CA description [default: local-dev]
  --config-file=FILE  OpenSSL config [default: openssl.cnf]
  --cn-client=STR     CN for client [default: docker-client]
  --cn-root=STR       CN for root [default: docker-CA]
  --client-ip=IP      Client IP to authorize
  --client-name=FQDN  Client name to authorize
  --days=N            Key expiration, days [default: 3650]
  --directory=PATH    Path for SSL files [default: ~/.docker/tls]
  --host-name=FQDN    Host server name
  --key-size=N        Key size, in bits [default: 4096]
  --port=N            TCP port number of docker-engine API [default: 4243]
  --no-encrypted-ca   Skip encryption on ca-key.pem
  --subj-city=STR     CSR subject - city / location
  --subj-country=STR  CSR subject - country
  --subj-org=STR      CSR subject - organization
  --subj-ou=STR       CSR subject - organizational unit
  --subj-state=STR    CSR subject - state
  -v --verbose        Verbose output
  -h --help           List options
"""

import docopt
import os.path
import subprocess

DOCKER_SSL_PATH = '/etc/docker/ssl'
OPENSSL_PATH = '/usr/bin/openssl'


class GenCerts(object):
    def __init__(self, args):
        self.ask_passphrase = args['--ask-passphrase']
        self.ca_file = args['--ca-file']
        self.ca_subject = args['--ca-subject']
        self.config_file = args['--config-file']
        self.cn_client = args['--cn-client']
        self.cn_root = args['--cn-root']
        self.client_ips = args['--client-ip']
        self.client_names = args['--client-name']
        self.days = int(args['--days'])
        self.directory = args['--directory']
        self.encrypted_ca = not args['--no-encrypted-ca']
        self.host_names = args['--host-name']
        self.key_size = int(args['--key-size'])
        self.port = int(args['--port'])
        self.subject_locale = ''
        if args['--subj-city']:
            self.subject_locale += '/L=%s' % args['--subj-city']
        if args['--subj-country']:
            self.subject_locale += '/C=%s' % args['--subj-country']
        if args['--subj-state']:
            self.subject_locale += '/ST=%s' % args['--subj-state']
        if args['--subj-org']:
            self.subject_locale += '/O=%s' % args['--subj-org']
        if args['--subj-ou']:
            self.subject_locale += '/OU=%s' % args['--subj-ou']
        self.verbose = args['--verbose']

    def gen_ca_key(self):
        openssl('genrsa %(encrypt)s -out %(ca)s-key.pem %(size)d' % {
            'ca': self.ca_file, 'size': self.key_size,
            'encrypt': '-aes256' if self.encrypted_ca else ''})
        openssl('req -new -x509 -days %(days)d -key %(ca)s-key.pem '
                '-out %(ca)s.pem -subj "/CN=%(cn_root)s%(locale)s"' % {
                    'days': self.days,
                    'ca': self.ca_file,
                    'cn_root': self.cn_root,
                    'locale': self.subject_locale})

    def gen_key_and_cert(self, fqdn, suffix):
        openssl('genrsa %(encrypt)s -out %(key)s.pem %(size)d' % {
            'key': self.keyname(fqdn, suffix), 'size': self.key_size,
            'encrypt': '-aes256' if self.ask_passphrase else ''})
        openssl('req -new -key %(key)s.pem '
                '-out %(cert)s.csr '
                '-subj "/CN=%(cn)s%(locale)s" -config %(config_file)s' % {
                    'key': self.keyname(fqdn, suffix),
                    'cert': self.certname(fqdn, suffix),
                    'cn': fqdn, 'config_file': self.config_file,
                    'locale': self.subject_locale})
        openssl('x509 -req -in %(cert)s.csr -CA %(ca)s.pem -days %(days)d '
                '-CAkey %(ca)s-key.pem -CAcreateserial -out '
                '%(cert)s.pem -extensions v3_req -extfile %(config_file)s' % {
                    'cert': self.certname(fqdn, suffix),
                    'ca': self.ca_file,
                    'days': self.days,
                    'config_file': self.config_file})

    def create_config_file(self, filename, alt_names, alt_ips):
        config_header = r"""[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name

[req_distinguished_name]

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
"""
        alt_template = r"""
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names

[alt_names]
%(dns)s
%(ip)s
"""
        with open(filename, 'w') as f:
            f.write(config_header)
            if alt_names or alt_ips:
                dns_items = '\n'.join(
                    ['DNS.%d = %s' % (k + 1, v) for k, v
                     in enumerate(alt_names)])
                ip_items = '\n'.join(
                    ['IP.%d = %s' % (k + 1, v) for k, v
                     in enumerate(alt_ips)])
                f.write(alt_template % {'dns': dns_items, 'ip': ip_items})

    def docker_opts(self, fqdn, suffix):
        opts = """DOCKER_OPTS="\\
    -H tcp://0.0.0.0:%(port)d -H unix:///var/run/docker.sock \\
    --tlsverify --tlscacert=%(ssl)s/%(ca)s.pem \\
    --tlscert=%(ssl)s/%(cert)s.pem \\
    --tlskey=%(ssl)s/%(key)s.pem"
"""
        with open('%s-opts' % fqdn, 'w') as f:
            f.write(opts % {
                'port': self.port, 'ca': self.ca_file,
                'ssl': DOCKER_SSL_PATH, 'key': self.keyname(fqdn, suffix),
                'cert': self.certname(fqdn, suffix)})

    @staticmethod
    def keyname(fqdn, suffix):
        return '%(fqdn)s-%(suffix)s-key' % {'fqdn': fqdn, 'suffix': suffix}

    @staticmethod
    def certname(fqdn, suffix):
        return '%(fqdn)s-%(suffix)s-cert' % {'fqdn': fqdn, 'suffix': suffix}


def openssl(cmd):
    subprocess.check_call(OPENSSL_PATH + ' ' + cmd, shell=True)


def main():
    gencerts = GenCerts(docopt.docopt(__doc__))
    try:
        os.makedirs(os.path.expanduser(gencerts.directory))
    except OSError as ex:
        if ex.strerror != 'File exists':
            raise
    os.chdir(os.path.expanduser(gencerts.directory))
    os.umask(0o77)
    if not os.path.isfile('%s.pem' % gencerts.ca_file):
        gencerts.gen_ca_key()
    if gencerts.verbose > 1:
        print('CA contains:')
        openssl('x509 -noout -issuer -subject -dates -in %(ca)s.pem' % {
            'ca': gencerts.ca_file})
    gencerts.create_config_file(
        gencerts.config_file, gencerts.client_names,
        gencerts.client_ips)
    for fqdn in gencerts.client_names:
        gencerts.gen_key_and_cert(fqdn, 'client')
        if gencerts.verbose > 1:
            openssl('x509 -noout -issuer -subject -dates -in %(cert)s.pem' % {
                'cert': GenCerts.certname(fqdn, 'client')})
    for fqdn in gencerts.host_names:
        gencerts.gen_key_and_cert(fqdn, 'server')
        if gencerts.client_ips:
            gencerts.docker_opts(fqdn, 'server')
        if gencerts.verbose:
            print('export DOCKER_HOST=tcp://%s:%d' % (fqdn, gencerts.port))
            print('export DOCKER_CERT_PATH=%s' % gencerts.directory)
            print('export DOCKER_TLS_VERIFY=1')


if __name__ == '__main__':
    main()
