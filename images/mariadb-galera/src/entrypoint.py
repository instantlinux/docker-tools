#!/usr/bin/env python

# MariaDB cluster startup
#  This script upon startup waits for a specified number of nodes
#  (environment variable CLUSTER_SIZE) to report state of files
#  in /var/lib/mysql to etcd. It will halt if the cluster is
#  degraded, with fewer than that number of nodes. It follows the
#  Galera documentation's specified steps to bring up nodes in
#  proper sequence, by electing a leader with the most current data.
#
# created 4 Jun 2017 by rich braun richb at instantlinux. net
#
# License: https://www.apache.org/licenses/LICENSE-2.0

import os
import logging
import random
import re
import socket
import subprocess
import sys
import time

import etcd

# Constants
DEFAULT_CLUSTER_SIZE = 3
ETCD_PREFIX = '/galera'

KEY_CLUSTER_UPDATE_TIMER = 'update_timer'
KEY_HEALTH = 'health'
KEY_RECOVERED_POSITION = 'recovered_position'
KEY_SAFE_TO_BOOTSTRAP = 'safe_to_bootstrap'
KEY_WSREP_GCOMM_UUID = 'wsrep_gcomm_uuid'
KEY_WSREP_LOCAL_STATE_COMMENT = 'wsrep_local_state_comment'

STATUS_DEGRADED = 'degraded'
STATUS_INIT = 'initializing'
STATUS_INSTALL = 'installing'
STATUS_NEW = 'new'
STATUS_OK = 'ok'
STATUS_RESTARTING = 'restarting'

DEFAULT_TTL = 10
TTL_DIR = 900
TTL_INITIALIZING = 600
TTL_LOCK = 90
TTL_STACK_UP = 60
TTL_UPDATE_TIMER = 90


class ClusterDegradedError(Exception):
    pass


class NotYetImplementedError(Exception):
    pass


class MariaDBCluster(object):

    def __init__(self):
        self.name = os.environ['CLUSTER_NAME']
        try:
            self.join = os.environ['CLUSTER_JOIN']
        except KeyError:
            self.join = None
        try:
            self.cluster_size = int(os.environ['CLUSTER_SIZE'])
        except KeyError:
            self.cluster_size = DEFAULT_CLUSTER_SIZE
        self.reinstall_ok = 'REINSTALL_OK' in os.environ
        self.ttl_initializing = TTL_INITIALIZING
        self.ttl_lock = TTL_LOCK
        self.ttl_stack_up = TTL_STACK_UP
        self.ttl_update_timer = TTL_UPDATE_TIMER
        self.update_timer_active = False
        self.my_hostname = socket.gethostname()
        self.my_ipv4 = socket.gethostbyname(self.my_hostname)
        self.data_dir = self._invoke(
            'mysqld --verbose --help --wsrep-cluster-address=none '
            '| grep ^datadir').split()[1]
        self.root_password = self._get_root_password()
        self.xtrabackup_password = self._get_xtrabackup_password()
        self.prev_address = None

    def share_initial_state(self, discovery):
        """Query data_dir contents for initial state, and share via
        the etcd discovery service

        params: discovery - connection to etcd
        """

        self.discovery = discovery
        if self._is_new_install():
            self.health = STATUS_NEW
            discovery.set_key(KEY_HEALTH, self.health, ttl=self.ttl_stack_up)
        else:
            self.health = STATUS_INIT
            discovery.set_key(KEY_HEALTH, self.health, ttl=self.ttl_stack_up)
            try:
                discovery.set_key(KEY_SAFE_TO_BOOTSTRAP,
                                  self._is_safe_to_boot(),
                                  ttl=self.ttl_stack_up)
            except AssertionError:
                pass
            try:
                discovery.set_key(KEY_RECOVERED_POSITION,
                                  self._get_recovered_position(),
                                  ttl=self.ttl_stack_up)
            except AssertionError:
                pass
            gcomm_uuid = self._get_gcomm_uuid()
            if gcomm_uuid:
                discovery.set_key(KEY_WSREP_GCOMM_UUID,
                                  gcomm_uuid,
                                  ttl=self.ttl_stack_up)

    def _get_root_password(self):
        """get root password from environment or Docker secret

        if not specified, and environment MYSQL_RANDOM_ROOT_PASSWORD has
        any value, a new random pw will be generated
        """

        if 'MYSQL_ROOT_PASSWORD' in os.environ:
            return os.environ['MYSQL_ROOT_PASSWORD']
        try:
            with open(os.path.join('/run/secrets',
                                   'mysql-root-password'), 'r') as f:
                pw = f.read()
            return pw
        except IOError:
            pass
        if 'MYSQL_RANDOM_ROOT_PASSWORD' in os.environ:
            return '%020x' % random.randrange(16**20)
        else:
            raise AssertionError('Root password must be specified')

    def _get_xtrabackup_password(self):
        if 'XTRABACKUP_PASSWORD' in os.environ:
            return os.environ['XTRABACKUP_PASSWORD']
        try:
            with open(os.path.join('/run/secrets',
                                   'xtrabackup-password'), 'r') as f:
                pw = f.read()
            return pw
        except IOError:
            pass
        return ''

    def _is_new_install(self):
        return (not os.path.exists(os.path.join(self.data_dir, 'ibdata1')) and
                not os.path.exists(os.path.join(self.data_dir, 'mysql')))

    def _is_safe_to_boot(self):
        """query grastate.dat safe_to_bootstrap value"""

        try:
            with open(os.path.join(self.data_dir, 'grastate.dat'), 'r') as f:
                for line in f:
                    if line.split(':')[0] == KEY_SAFE_TO_BOOTSTRAP:
                        return int(line.split(':')[1])
        except IOError as ex:
            logging.error({'action': '_is_safe_to_boot', 'status': 'error',
                           'message': ex.message})
        raise AssertionError('Invalid content or missing grastate.dat')

    def _reset_grastate(self, value=1):
        """reset safe_to_bootstrap value on current node"""

        self._invoke(
            'sed -i "s/safe_to_bootstrap.*/safe_to_bootstrap: %d/" %s' %
            (value, os.path.join(self.data_dir, 'grastate.dat')))

    def wait_checkin(self, retry_interval=5):
        """wait for all cluster nodes to check in

        looks for self.cluster_size nodes to report health
        returns a dict of status values keyed by nodes' ipv4 addresses

        returns: dict
        raises: ClusterDegradedError
        """

        while self.discovery.get_key(KEY_HEALTH, ipv4=self.my_ipv4):
            instances = self.discovery.get_key('')
            health_status = {
                item: self.discovery.get_key(KEY_HEALTH, ipv4=item)
                for item in instances
            }
            retval = dict((key, val) for key, val in
                          health_status.iteritems() if val)
            if len(retval) == self.cluster_size:
                break
            time.sleep(retry_interval)
        if len(retval) >= self.cluster_size:
            logging.info(dict(retval, **{
                'action': 'wait_checkin', 'status': 'ok',
                'peers': ','.join(instances)}))
            return retval
        logging.error(dict(retval, **{
            'action': 'wait_checkin', 'status': 'error'}))
        raise ClusterDegradedError(
            'Insufficient number (%d) of nodes (need %d)' %
            (len(retval), self.cluster_size))

    def _get_recovered_position(self):
        """parse recovered position using wsrep-recover

        returns: int
        raises: AssertionError if not found
        """
        uuid_pat = re.compile('[a-z0-9]*-[a-z0-9]*:-*[0-9]', re.I)
        filename = os.path.join(self.data_dir, '%s.err' % self.my_hostname)
        self._invoke('mysqld_safe --wsrep-cluster-address=gcomm:// '
                     '--wsrep-recover --skip-syslog')
        with open(filename, 'r') as f:
            for line in f:
                match = re.match(uuid_pat, line)
                if match:
                    return int(match.split(':')[1])
        os.unlink(filename)
        raise AssertionError('No recovery position identified')

    def _get_gcomm_uuid(self):
        """query gvwstate.dat my_uuid value

        returns: None (from a clean shutdown) or my_uuid value
        """

        try:
            with open(os.path.join(self.data_dir, 'gvwstate.dat'), 'r') as f:
                for line in f:
                    if line.split(':')[0] == 'my_uuid':
                        return line.split(':')[1].strip()
        except IOError:
            pass
        return None

    def _install_new_database(self, timeout=30):
        """run the mysql_install_db installer and set up system users"""

        script_setusers = r"""
        SET @@SESSION.SQL_LOG_BIN=0;
        DELETE FROM mysql.user;
        CREATE USER 'root'@'%%' IDENTIFIED BY '%(mysql_root_password)s';
        GRANT ALL ON *.* TO 'root'@'%%' WITH GRANT OPTION;
        CREATE USER 'xtrabackup'@'localhost' IDENTIFIED BY
          '%(xtrabackup_password)s';
        GRANT RELOAD,LOCK TABLES,REPLICATION CLIENT ON *.* TO
          'xtrabackup'@'localhost';
        DROP DATABASE IF EXISTS test;
        FLUSH PRIVILEGES;
        SELECT user,host FROM mysql.user;
        """

        logging.info({'action': '_install_new_database', 'status': 'start'})
        opts = '--user=mysql --datadir=%s' % self.data_dir
        mysql_client = '/usr/bin/mysql --protocol=socket -u root'
        sys.stdout.write(self._invoke('mysql_install_db %s --rpm' % opts))
        start_time = time.time()
        proc = self._run_background(
            'exec /usr/sbin/mysqld %s --skip-networking' % opts)
        while time.time() - start_time > timeout:
            time.sleep(1)
            if self._invoke('%s -e "SELECT 1;"' % mysql_client) == ['1', '1']:
                break
        if time.time() - start_time > timeout:
            logging.error({'action': '_install_new_database',
                           'message': 'timeout', 'status': 'error'})
            time.sleep(60)
            exit(1)
        sys.stdout.write(self._invoke(
            'mysql_tzinfo_to_sql /usr/share/zoneinfo | '
            'sed "s/Local time zone must be set--see zic manual page/FCTY/" | '
            '%s mysql' % mysql_client))
        sys.stdout.write(self._invoke('%(mysql)s -e "%(script)s"' % {
            'mysql': mysql_client,
            'script': script_setusers % {
                'mysql_root_password': self.root_password,
                'xtrabackup_password': self.xtrabackup_password
            }}))
        proc.terminate()
        proc.wait()
        logging.info({'action': '_install_new_database', 'status': 'ok'})
        # TODO
        sys.stdout.write(self._invoke('ps -eaux'))
        sys.stdout.write(self._invoke('echo lookforthis'))

    def start_database(self, cluster_address='', wsrep_new_cluster=False,
                       cmdarg=None):
        command = (
            'exec /usr/sbin/mysqld --wsrep_cluster_name=%(cluster_name)s '
            '--wsrep-cluster-address="gcomm://%(address)s" '
            '--wsrep_sst_auth="xtrabackup:%(xtrabackup_password)s"' % {
                'cluster_name': self.name,
                'address': cluster_address,
                'xtrabackup_password': self.xtrabackup_password})
        if wsrep_new_cluster:
            command += ' --wsrep-new-cluster'
        if cmdarg:
            command += ' %s' % cmdarg
        logging.info({
            'action': 'start_database',
            'status': 'start',
            'cluster_name': self.name,
            'cluster_address': cluster_address,
            'wsrep_new_cluster': wsrep_new_cluster,
            'cmdarg': cmdarg
        })
        self.proc = self._run_background(command)

    def start(self, ipv4, initial_state=STATUS_RESTARTING, cluster_address='',
              install_ok=False):
        """start database
        Bootstrap if running on the node elected as leader (param 'ipv4')

        Otherwise wait for bootstrap lock release and join cluster
        """

        if self.my_ipv4 == ipv4:
            # acquire lock if elected as leader
            self.discovery.acquire_lock('bootstrap', ttl=self.ttl_lock)
            self.discovery.set_key(KEY_HEALTH, initial_state)
            if initial_state == STATUS_INSTALL and install_ok:
                self._install_new_database()
            self.start_database(wsrep_new_cluster=True)
            self.discovery.release_lock('bootstrap')
        else:
            # join other nodes after first is up
            while (self.discovery.get_key(ipv4, KEY_HEALTH) in
                   [STATUS_NEW, STATUS_INIT]):
                time.sleep(1)
            self.discovery.acquire_lock('bootstrap', ttl=self.ttl_lock)
            if self.health == STATUS_NEW:
                if not (initial_state == STATUS_INSTALL or install_ok):
                    logging.error({
                        'action': 'start',
                        'status': 'error',
                        'message': 'missing_data_reinstall_is_not_ok'})
                    raise ClusterDegradedError('Missing database')
            self.start_database(cluster_address=cluster_address)
            self.discovery.release_lock('bootstrap')

    def restart_database(self, node_list):
        """Restart down cluster"""

        peer_state = {ipv4: self.discovery.get_key_recursive('', ipv4=ipv4)
                      for ipv4 in node_list}
        safe_to_bootstrap = 0
        recovered_position = -1
        recoverable_nodes = 0
        for ipv4, peer in peer_state.iteritems():
            # Leader election
            if peer.get(KEY_HEALTH) == STATUS_NEW:
                continue
            if int(peer.get(KEY_SAFE_TO_BOOTSTRAP, 0)) == 1:
                safe_to_bootstrap += 1
                addr_bootstrap = ipv4
            val = peer.get(KEY_RECOVERED_POSITION, 0)
            if val is not None:
                recoverable_nodes += 1
            if int(val) > recovered_position:
                recovered_position = int(val)
                addr_highest_pos = ipv4

        if safe_to_bootstrap == 1:
            # Cluster was shut down normally
            logging.info({'action': 'restart_database',
                          'message': 'restart_safe',
                          'leader': addr_bootstrap})
            self._restart(addr_bootstrap)
        elif recoverable_nodes >= self.cluster_size - 1:
            # Cluster crashed
            logging.info({'action': 'restart_database',
                          'message': 'restart_recovery',
                          'leader': addr_highest_pos,
                          'position': recovered_position})
            self._restart(addr_highest_pos,
                          reset_grastate=(addr_highest_pos == self.my_ipv4))
        else:
            logging.error({
                'action': 'restart_database',
                'status': 'error',
                'message': 'unhandled_state',
                'safe_to_bootstrap': safe_to_bootstrap,
                'recoverable_nodes': recoverable_nodes,
                'recovered_position': recovered_position
            })
            # Leave nodes up long enough to diagnose
            time.sleep(300)
            raise NotYetImplementedError('Unhandled cluster state')

    def _restart(self, ipv4, reset_grastate=False):
        logging.info({'action': '_restart', 'leader': ipv4,
                      'reset_grastate': reset_grastate})
        if reset_grastate:
            self._reset_grastate()
        self.start(ipv4, cluster_address=ipv4, install_ok=self.reinstall_ok)

    def _update_cluster_address(self):
        """find healthy nodes and update wsrep_cluster_address

        Once all of the cluster's nodes are in Synced state, each should
        be updated with the peer list of nodes in order to ensure full
        HA operation.

        A randomized timer is needed in order to stagger these updates;
        if they all happen within less than a minute, replication will
        stall and the cluster will go out of sync.
        """

        nodes = self.discovery.get_key('')
        synced = [
            ipv4 + ':' for ipv4 in nodes if
            self.discovery.get_key(KEY_WSREP_LOCAL_STATE_COMMENT,
                                   ipv4=ipv4) == 'Synced']
        address = 'gcomm://' + ','.join(sorted(synced))
        log_info = {'action': '_update_cluster_address',
                    'prev_address': self.prev_address,
                    'cluster_address': address}
        if (len(synced) >= self.cluster_size and address != self.prev_address
                and not self.discovery.get_key(KEY_CLUSTER_UPDATE_TIMER,
                                               ipv4=self.my_ipv4)):
            if not self.update_timer_active:
                ttl = (self.ttl_update_timer +
                       random.randrange(self.ttl_update_timer))
                self.discovery.set_key(KEY_CLUSTER_UPDATE_TIMER, '1', ttl=ttl)
                self.update_timer_active = True
                logging.info(dict(log_info, **{
                    'status': 'start_timer', 'ttl': ttl}))
            else:
                self.update_timer_active = False
                self._invoke(
                    'mysql -u root -p%(pw)s -e '
                    '"SET GLOBAL wsrep_cluster_address=\'%(address)s\'";' %
                    {'pw': self.root_password, 'address': address})
                self.prev_address = address
                logging.info(dict(log_info, **{'status': 'ok'}))

    def report_status(self):
        """update etcd keys (health, etc) with current state"""

        def _set_wsrep_key(key):
            val = self._invoke(
                'mysql -u root -p%(pw)s -Bse '
                '"SHOW STATUS LIKE \'%(key)s\';"' % {
                    'pw': self.root_password, 'key': key}).split()[1]
            self.discovery.set_key(key, val, ttl=self.discovery.ttl)
            return val

        try:
            if _set_wsrep_key(KEY_WSREP_LOCAL_STATE_COMMENT) == 'Synced':
                self._update_cluster_address()
                self.discovery.set_key(KEY_HEALTH, STATUS_OK)
            else:
                self.discovery.set_key(KEY_HEALTH, STATUS_DEGRADED)
        except IndexError:
            pass

    @staticmethod
    def _invoke(command):
        """invoke a shell command and return its stdout"""

        # TODO
        if 'SHOW STATUS LIKE' not in command:
            logging.info({'action': '_invoke', 'command': command})
        proc = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE)
        return proc.communicate()[0]

    @staticmethod
    def _run_background(command):
        """run a command in background"""

        return subprocess.Popen(command, shell=True)


class DiscoveryService(object):

    def __init__(self, nodes, cluster):
        self.ipv4 = socket.gethostbyname(socket.gethostname())
        self.etcd = etcd.Client(host=nodes, allow_reconnect=True,
                                lock_prefix='/%s/_locks' % cluster)
        self.prefix = ETCD_PREFIX
        self.cluster = cluster
        try:
            self.ttl = int(os.environ['TTL'])
        except KeyError:
            self.ttl = DEFAULT_TTL
        self.ttl_dir = TTL_DIR
        self.locks = {}

    def set_key(self, keyname, value, ttl=None):
        logging.debug({'action': 'set_key', 'keyname': keyname,
                       'value': value})
        try:
            self.etcd.write('%(prefix)s/%(cluster)s/%(ipv4)s' % {
                'prefix': self.prefix, 'cluster': self.cluster,
                'ipv4': self.ipv4}, None, dir=True, ttl=self.ttl_dir)
        except etcd.EtcdNotFile:
            pass
        self.etcd.write('%(prefix)s/%(cluster)s/%(ipv4)s/%(keyname)s' % {
                            'prefix': self.prefix, 'cluster': self.cluster,
                            'ipv4': self.ipv4, 'keyname': keyname
                        },
                        value, ttl=ttl if ttl else DEFAULT_TTL)

    def get_key(self, keyname, ipv4=None):
        """Fetch the key for a given ipv4 node

        returns: scalar value or list of child keys
        """

        log_info = {
            'action': 'get_key',
            'keyname': keyname,
            'ipv4': ipv4
        }
        key_path = '%(prefix)s/%(cluster)s' % {
            'prefix': self.prefix, 'cluster': self.cluster}
        if ipv4:
            key_path += '/' + ipv4
        if keyname:
            key_path += '/' + keyname
        try:
            item = self.etcd.read(key_path)
        except etcd.EtcdKeyNotFound:
            logging.debug(dict(log_info, **{
                'status': 'error',
                'message': 'not_found'}))
            return None

        log_info['status'] = 'ok'
        if item.dir:
            retval = [child.key[len(key_path) + 1:]
                      for child in item.children]
            return retval
        else:
            logging.debug(dict(log_info, **{
                'value': item.value}))
            return item.value

    def get_key_recursive(self, keyname, ipv4=None, nest_level=0):
        """Fetch all keys under the given node """

        assert nest_level < 10, 'Recursion too deep'
        retval = self.get_key(keyname, ipv4=ipv4)
        if type(retval) is list:
            return {key: self.get_key_recursive(key, ipv4=ipv4,
                                                nest_level=nest_level + 1)
                    for key in retval}
        else:
            return retval

    def acquire_lock(self, lock_name, ttl=DEFAULT_TTL):
        """acquire cluster lock - used upon electing leader"""

        logging.info({'action': 'acquire_lock', 'lock_name': lock_name})
        self.locks[lock_name] = etcd.Lock(self.etcd, lock_name)
        self.locks[lock_name].acquire(lock_ttl=ttl)

    def release_lock(self, lock_name):
        """release cluster lock"""

        logging.info({'action': 'release_lock', 'lock_name': lock_name})
        self.locks[lock_name].release()


class LoggingDictFormatter(logging.Formatter):
    def format(self, record):
        if type(record.msg) is dict:
            record.msg = self._dict_to_str(record.msg)
        return super(LoggingDictFormatter, self).format(record)

    @staticmethod
    def _dict_to_str(values):
        """Convert a dict to string key1=val key2=val ... """
        return ' '.join(['%s=%s' % (key, val)
                         for key, val in values.iteritems()])


def setup_logging(level=logging.INFO, output=sys.stdout):
    """For Docker, send logging to stdout"""

    logger = logging.getLogger()
    handler = logging.StreamHandler(output)
    handler.setFormatter(LoggingDictFormatter(
        '%(asctime)s %(levelname)s %(message)s', '%Y-%m-%d %H:%M:%S'))
    logger.setLevel(level)
    logger.addHandler(handler)


def main():
    setup_logging()
    cluster = MariaDBCluster()
    logging.info({'action': 'main', 'status': 'start',
                  'my_ipv4': cluster.my_ipv4})
    cluster.share_initial_state(DiscoveryService(
        tuple([(item.split(':')[0], int(item.split(':')[1]))
               for item in os.environ['DISCOVERY_SERVICE'].split(',')]),
        cluster.name))
    try:
        peers = cluster.wait_checkin(retry_interval=5)
        time.sleep(6)
    except ClusterDegradedError as ex:
        logging.error({'action': 'main', 'status': 'failed',
                       'message': ex.message})
        exit(1)

    if cluster.join:
        cluster.start_database(cluster_address=cluster.join)

    elif all(status == STATUS_NEW for status in peers.values()):
        # No data on any node: safe to install new cluster
        first_node = sorted(peers.keys())[0]
        cluster.start(first_node, initial_state=STATUS_INSTALL,
                      cluster_address=first_node, install_ok=True)

    elif STATUS_OK in peers.values():
        # At least one instance is synchronized, join them
        cluster.start_database(cluster_address=','.join(
            [peer for peer, status in peers.iteritems()
             if status == STATUS_OK]))
    else:
        # Cluster is down
        cluster.restart_database(peers.keys())

    while True:
        cluster.report_status()
        time.sleep(cluster.discovery.ttl * 0.8)
        assert cluster.proc.returncode is None, 'MariaDB daemon died'


if __name__ == '__main__':
    main()
