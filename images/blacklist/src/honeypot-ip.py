#!/usr/bin/env python
"""
honeypot-ip.py

  created 25-apr-2017 by richb@instantlinux.net

  Looks for IP address in last Received header of incoming email
  message on stdin. Performs insert-update on the DNS blacklist
  database entry for that IP. Since spammers usually send from
  multiple IPs in a subnet, a range of addresses can be specified.
  First-pass of this code enables a fixed-size block to be specified;
  TODO we can query BGP tables or GeoIP databases to make this a
  bit smarter.

Usage:
  honeypot.py [--db-config=FILE] [--db-host=HOST] [--db-name=DB]
              [--db-pass=PW] [--db-user=USER] [--db-table=TABLE]
              [--cidr-min-size=N] [--honeypot=EMAIL]... [--notes=STR]
              [--pipe-stdout] [--relay=PAT] [-q] [-v]...

Options:
  --db-config=FILE     Database config file [default: ~/.my.cnf]
  --db-host=HOST       Database host fqdn or IP
  --db-name=DB         Database name [default: blacklist]
  --db-pass=PW         Database password (use --db-config instead!)
  --db-user=USER       Database user [default: blacklist]
  --db-table=TABLE     Database table [default: ips]
  --cidr-min-size=N    Minimum CIDR address block size [default: 32]
  --honeypot=EMAIL     Honeypot email address
  --notes=STR          Remarks about this entry
  --pipe-stdout, -o    Copy stdin to stdout
  --quiet, -q          Quiet
  --relay=PAT          Relay server accepting outside email
  --verbose -v         Verbosity
"""

import ConfigParser
import docopt
import email
import os
import re
import socket
from sqlalchemy import Column, Integer, String
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from sqlalchemy import create_engine
import sys
import urllib

SQLBase = declarative_base()


class HoneypotMsg(object):

    def __init__(self, args):
        self.dsn = {
            'host': args['--db-host'],
            'database': args['--db-name'],
            'password': args['--db-pass'],
            'user': args['--db-user']
        }
        if args['--db-config']:
            self._read_config(args['--db-config'])
        self.db_table = args['--db-table']
        print args
        self.cidr_min_size = int(args['--cidr-min-size'])
        self.honeypots = args['--honeypot']
        self.notes = args['--notes']
        self.pipe_stdout = args['--pipe-stdout']
        self.quiet = args['--quiet']
        if args['--relay']:
            self.relay = re.compile(args['--relay'])
        else:
            self.relay = None
        dsn = 'mysql://%(user)s:%(pw)s@%(host)s/%(db)s' % {
            'user': self.dsn['user'],
            'pw': urllib.quote_plus(self.dsn['password']),
            'host': self.dsn['host'], 'db': self.dsn['database']}
        self.sql_engine = create_engine(dsn)
        SQLBase.metadata.bind = self.sql_engine
        DBSession = sessionmaker(bind=self.sql_engine)
        self.db_session = DBSession()
        self.verbose = args['--verbose']
        if self.verbose > 1:
            print 'dsn: %s' % dsn
            print 'honeypots: %s' % ','.join(self.honeypots)

    def find_received_ip(self, msg, relay):
        if relay:
            try:
                received = [header for i, header in enumerate(msg.get_all(
                    'Received')) if re.search(relay, header)][0]
            except IndexError:
                print 'Relay not found in headers'
                sys.exit(1)
        else:
            received = msg.get_all('Received')[-1]
        if self.verbose > 1:
            print 'Received: %s' % received
            print 'To: %s' % msg.get('To')
        pat = re.compile("\[\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3}\]")
        ip = re.findall(pat, received)[0][1:-1]
        try:
            socket.inet_aton(ip)
        except socket.error:
            pass
        return ip

    def is_honeypot(self, msg):
        if not len(self.honeypots):
            return True
        recipient = email.utils.parseaddr(msg.get('To'))[1]
        retval = recipient in self.honeypots
        if self.verbose:
            if retval:
                print 'Message recipient %s is in honeypot list' % recipient
            else:
                print 'Message recipient %s is allowed' % recipient
        return retval

    def insert_ip(self, ip, cidr_size):
        if cidr_size > 32 or cidr_size < 16:
            raise ValueError("CIDR block length must be 16 to 32")
        ip_net = ((
            int(socket.inet_aton(ip).encode('hex'), 16) >> 32 - cidr_size)
            << 32 - cidr_size)
        ip_val = socket.inet_ntoa(hex(ip_net)[2:].decode('hex'))
        if cidr_size < 32:
            ip_val += '/%d' % cidr_size
        lookup = self.db_session.query(IP).get(ip_val)
        if lookup:
            count = lookup.count + 1
        else:
            count = 1
        if self.verbose:
            print 'Inserting %s with count %d' % (ip_val, count)
        record = IP(ip_val, notes=self.notes, count=count)
        self.db_session.merge(record)
        self.db_session.commit()

    def _read_config(self, file):
        """TODO: default values shouldn't override those specified in file"""
        cfg = ConfigParser.ConfigParser()
        cfg.read(os.path.expanduser(file))
        for item in ['database', 'host', 'password', 'user']:
            if self.dsn[item]:
                continue
            self.dsn[item] = cfg.get('client', item)


class IP(SQLBase):
    __tablename__ = 'ips'
    attacknotes = Column(String)
    b_or_w = Column(String)
    count = Column(Integer)
    reportedby = Column(String)
    ipaddress = Column(Integer, primary_key=True)

    def __init__(self, ip, b_or_w='b', count=0, notes=''):
        self.attacknotes = notes
        self.b_or_w = b_or_w
        self.count = count
        self.reportedby = socket.gethostbyname(socket.gethostname())
        self.ipaddress = ip


def main():
    obj = HoneypotMsg(docopt.docopt(__doc__))
    msg = email.message_from_file(sys.stdin)
    if obj.is_honeypot(msg):
        obj.insert_ip(obj.find_received_ip(msg, obj.relay),
                      obj.cidr_min_size)
    if obj.pipe_stdout:
        sys.stdout.write(msg.as_string())


if __name__ == '__main__':
    main()
