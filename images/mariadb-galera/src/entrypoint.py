#!/usr/bin/env python3

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

import logging
import os
import pwd
import random
import re
import socket
import subprocess
import sys
import time

import etcd3


class Constants(object):
    DATA_DIR = '/var/lib/mysql'
    DEFAULT_CLUSTER_SIZE = 3
    ETCD_PREFIX = '/galera'
    LOG_DIR = '/var/log/mysql'

    ETCD_RETRIES = 2
    ETCD_RETRY_WAIT = 5

    KEY_CLUSTER_UPDATE_TIMER = 'update_timer'
    KEY_HEALTH = 'health'
    KEY_HOSTNAME = 'hostname'
    KEY_RECOVERED_POSITION = 'recovered_position'
    KEY_SAFE_TO_BOOTSTRAP = 'safe_to_bootstrap'
    KEY_WSREP_GCOMM_UUID = 'wsrep_gcomm_uuid'
    KEY_WSREP_LOCAL_STATE_COMMENT = 'wsrep_local_state_comment'

    STATUS_DEGRADED = 'degraded'
    STATUS_DONOR = 'donor'
    STATUS_INIT = 'initializing'
    STATUS_INSTALL = 'installing'
    STATUS_NEW = 'new'
    STATUS_OK = 'ok'
    STATUS_RESTARTING = 'restarting'

    DEFAULT_TTL = 10
    TTL_DIR = 900
    TTL_LOCK = 45
    TTL_STACK_UP = 600
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
            self.cluster_size = Constants.DEFAULT_CLUSTER_SIZE
        self.reinstall_ok = 'REINSTALL_OK' in os.environ
        self.ttl_lock = Constants.TTL_LOCK
        self.ttl_stack_up = Constants.TTL_STACK_UP
        self.ttl_update_timer = Constants.TTL_UPDATE_TIMER
        self.update_timer_active = False
        self.my_hostname = socket.gethostname()
        self.my_ipv4 = socket.gethostbyname(self.my_hostname)
        self.data_dir = self._invoke(
            'mariadbd --verbose --help --wsrep-cluster-address=none '
            '| grep ^datadir').split()[1].strip()
        self.root_password = self._get_root_password()
        self.prev_address = None

    def share_initial_state(self, discovery):
        """Query data_dir contents for initial state, and share via
        the etcd discovery service

        params: discovery - connection to etcd
        """

        self.discovery = discovery
        if self._is_new_install():
            self.health = Constants.STATUS_NEW
            discovery.set_key(Constants.KEY_HEALTH, self.health,
                              ttl=self.ttl_stack_up)
        else:
            self.health = Constants.STATUS_INIT
            discovery.set_key(Constants.KEY_HEALTH, self.health,
                              ttl=self.ttl_stack_up)
            discovery.set_key(Constants.KEY_HOSTNAME, self.my_hostname,
                              ttl=self.ttl_stack_up)
            try:
                discovery.set_key(Constants.KEY_SAFE_TO_BOOTSTRAP,
                                  str(self._is_safe_to_boot()),
                                  ttl=self.ttl_stack_up)
            except AssertionError:
                pass
            try:
                discovery.set_key(Constants.KEY_RECOVERED_POSITION,
                                  self._get_recovered_position(),
                                  ttl=self.ttl_stack_up)
            except AssertionError:
                pass
            gcomm_uuid = self._get_gcomm_uuid()
            if gcomm_uuid:
                discovery.set_key(Constants.KEY_WSREP_GCOMM_UUID,
                                  gcomm_uuid,
                                  ttl=self.ttl_stack_up)

    def wait_checkin(self, retry_interval=5):
        """wait for all cluster nodes to check in

        looks for self.cluster_size nodes to report health
        returns a dict of status values keyed by nodes' ipv4 addresses

        returns: dict
        raises: ClusterDegradedError
        """

        while self.discovery.get_key(Constants.KEY_HEALTH, ipv4=self.my_ipv4):
            retval = self._cluster_health()
            if len(retval) >= self.cluster_size:
                break
            time.sleep(retry_interval)
            logging.debug(dict(retval, **{
                'action': 'wait_checkin', 'status': 'retry'}))
        if len(retval) >= self.cluster_size:
            logging.info(dict(retval, **{
                'action': 'wait_checkin', 'status': 'ok',
                'peers': ','.join(retval.keys())}))
            return retval
        logging.error(dict(retval, **{
            'action': 'wait_checkin', 'status': 'error'}))
        raise ClusterDegradedError(
            'Insufficient number (%d) of nodes (need %d)' %
            (len(retval), self.cluster_size))

    def start_database(self, cluster_address='', wsrep_new_cluster=False,
                       cmdarg=None):
        command = (
            'exec /usr/sbin/mariadbd --wsrep_cluster_name=%(cluster_name)s '
            '--wsrep-cluster-address="gcomm://%(address)s"' % {
                'cluster_name': self.name,
                'address': cluster_address})
        if wsrep_new_cluster:
            command += ' --wsrep-new-cluster'
        if cmdarg:
            command += ' %s' % cmdarg
        os.chown(Constants.DATA_DIR, pwd.getpwnam('mysql').pw_uid, -1)
        os.chown(Constants.LOG_DIR, pwd.getpwnam('mysql').pw_uid, -1)
        if cluster_address:
            assert self._peer_reachable(cluster_address.split(',')[0]), (
                'Network connectivity problem for %s' % cluster_address)
        while True:
            # skew startup of concurrent launches by self.ttl_lock seconds
            ret = self.discovery.acquire_lock('bootstrap', ttl=self.ttl_lock)
            if not ret:
                logging.info({'action': 'acquire_lock',
                              'lock_name': 'bootstrap',
                              'message': 'ttl expired'})
            if Constants.STATUS_DONOR in self._cluster_health():
                # perform only one SST join at a time, loop until others done
                time.sleep(5)
            else:
                break
        logging.info({
            'action': 'start_database',
            'status': 'start',
            'cluster_name': self.name,
            'cluster_address': cluster_address,
            'wsrep_new_cluster': wsrep_new_cluster,
            'cmdarg': cmdarg
        })
        self.proc = self._run_background(command)

    def start(self, ipv4, initial_state=Constants.STATUS_RESTARTING,
              cluster_address='', install_ok=False):
        """start database
        Bootstrap if running on the node elected as leader (param 'ipv4')

        Otherwise join cluster
        """

        log_info = {'action': 'start', 'leader': ipv4}
        if self.my_ipv4 == ipv4:
            self.discovery.set_key(Constants.KEY_HEALTH, initial_state,
                                   ttl=self.ttl_stack_up)
            if initial_state == Constants.STATUS_INSTALL and install_ok:
                self._install_new_database()
            self.start_database(wsrep_new_cluster=True)
        else:
            # join other nodes after first is up
            # TODO: may need a timeout, currently relying on healthcheck
            logging.info(dict(log_info, **{'status': 'waiting'}))
            while (self.discovery.get_key(Constants.KEY_HEALTH, ipv4=ipv4) !=
                   Constants.STATUS_OK):
                time.sleep(1)
            if self.health == Constants.STATUS_NEW:
                if not (initial_state == Constants.STATUS_INSTALL or
                        install_ok):
                    logging.error(dict(log_info, **{
                        'status': 'error',
                        'message': 'missing_data_reinstall_is_not_ok'}))
                    raise ClusterDegradedError('Missing database')
            self.start_database(cluster_address=cluster_address)

    def restart_database(self, node_list):
        """Restart down cluster"""

        peer_state = {ipv4: self.discovery.get_key_recursive('', ipv4=ipv4)
                      for ipv4 in sorted(node_list)}
        safe_to_bootstrap = 0
        recovered_position = -1
        recoverable_nodes = 0
        for ipv4, peer in peer_state.items():
            # Leader election
            if (not peer or
                    peer.get(Constants.KEY_HEALTH) == Constants.STATUS_NEW):
                continue
            if int(peer.get(Constants.KEY_SAFE_TO_BOOTSTRAP, 0)) == 1:
                safe_to_bootstrap += 1
                addr_bootstrap = ipv4
            val = peer.get(Constants.KEY_RECOVERED_POSITION, 0)
            if val is not None:
                recoverable_nodes += 1
            if int(val) > recovered_position:
                recovered_position = int(val)
                addr_highest_pos = ipv4

        logging.debug({'action': 'restart',
                       'safe_to_bootstrap': safe_to_bootstrap,
                       'recoverable_nodes': recoverable_nodes})
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

    def report_status(self):
        """update etcd keys (health, etc) with current state"""

        def _set_wsrep_key(key):
            val = self._invoke(
                'mariadb -u root -p%(pw)s -Bse '
                '"SHOW STATUS LIKE \'%(key)s\';"' % {
                    'pw': self.root_password, 'key': key}).split()[1]
            self.discovery.set_key(key, val, ttl=self.discovery.ttl)
            return val

        log_info = {'action': 'report_status', 'status': 'warn'}

        try:
            self.discovery.set_key(Constants.KEY_HOSTNAME, self.my_hostname)
        except etcd3.Etcd3Exception as ex:
            logging.warn(dict(log_info, **{'message': str(ex)}))
        try:
            status = _set_wsrep_key(Constants.KEY_WSREP_LOCAL_STATE_COMMENT)
            if status == 'Synced':
                if self.cluster_size > 1:
                    self._update_cluster_address()
                self.discovery.set_key(Constants.KEY_HEALTH,
                                       Constants.STATUS_OK)
            elif status == 'Donor/Desynced':
                self.discovery.set_key(Constants.KEY_HEALTH,
                                       Constants.STATUS_DONOR)
            else:
                self.discovery.set_key(Constants.KEY_HEALTH,
                                       Constants.STATUS_DEGRADED)
        except IndexError:
            pass
        except etcd3.Etcd3Exception as ex:
            logging.warn(dict(log_info, **{'message': str(ex)}))

    def _get_root_password(self):
        """get root password from environment or Docker secret

        if not specified, and environment MYSQL_RANDOM_ROOT_PASSWORD has
        any value, a new random pw will be generated
        """

        if 'MYSQL_ROOT_PASSWORD' in os.environ:
            return os.environ['MYSQL_ROOT_PASSWORD']
        try:
            with open(os.path.join('/run/secrets',
                                   os.environ['ROOT_SECNAME']),
                      'r') as f:
                pw = f.read()
            return pw
        except IOError:
            pass
        if 'MYSQL_RANDOM_ROOT_PASSWORD' in os.environ:
            return '%020x' % random.randrange(16**20)
        else:
            raise AssertionError('Root password must be specified')

    def _is_new_install(self):
        return (not os.path.exists(os.path.join(self.data_dir, 'ibdata1')) and
                not os.path.exists(os.path.join(self.data_dir, 'mysql')))

    def _is_safe_to_boot(self):
        """query grastate.dat safe_to_bootstrap value"""

        try:
            with open(os.path.join(self.data_dir, 'grastate.dat'), 'r') as f:
                for line in f:
                    if line.split(':')[0] == Constants.KEY_SAFE_TO_BOOTSTRAP:
                        return int(line.split(':')[1])
        except IOError as ex:
            logging.error({'action': '_is_safe_to_boot', 'status': 'error',
                           'message': str(ex)})
        raise AssertionError('Invalid content or missing grastate.dat')

    def _reset_grastate(self, value=1):
        """reset safe_to_bootstrap value on current node"""

        self._invoke(
            'sed -i "s/safe_to_bootstrap.*/safe_to_bootstrap: %d/" %s' %
            (value, os.path.join(self.data_dir, 'grastate.dat')),
            ignore_errors=False)

    def _cluster_health(self):
        instances = self.discovery.get_key('')
        health_status = {
            item: self.discovery.get_key(Constants.KEY_HEALTH, ipv4=item)
            for item in instances
        }
        return dict((key, val) for key, val in
                    health_status.items() if val)

    def _get_recovered_position(self):
        """parse recovered position using wsrep-recover

        returns: int
        raises: AssertionError if not found
        """
        uuid_pat = re.compile(r"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-"
                              "[0-9a-f]{4}-[0-9a-f]{12}:[0-9]*")
        filename = os.path.join(self.data_dir, '%s.err' % self.my_hostname)
        self._invoke('mariadbd-safe --wsrep-cluster-address=gcomm:// '
                     '--wsrep-recover --skip-syslog', ignore_errors=False)
        with open(filename, 'r') as f:
            for line in f:
                match = re.search(uuid_pat, line)
                if match:
                    return int(match.group(0).split(':')[1])
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
        """run the mariadb-install-db installer and set up system users"""

        script_setusers = r"""
        SET @@SESSION.SQL_LOG_BIN=0;
        DELETE FROM mysql.user WHERE user='';
        RENAME USER 'root'@'localhost' TO 'root'@'%';
        DROP DATABASE IF EXISTS test;
        FLUSH PRIVILEGES;
        """

        logging.info({'action': '_install_new_database', 'status': 'start'})
        opts = '--user=mysql --datadir=%s --wsrep_on=OFF' % self.data_dir
        mysql_client = '/usr/bin/mariadb --protocol=socket -u root'
        sys.stdout.write(self._invoke('mariadb-install-db %s --rpm' %
                                      opts + ' --no-defaults'))
        start_time = time.time()
        proc = self._run_background(
            'exec /usr/sbin/mariadbd %s --skip-networking' % opts)
        while time.time() - start_time < timeout:
            time.sleep(1)
            if self._invoke('%s -e "SELECT 1;"' % mysql_client
                            ).split() == ['1', '1']:
                break
        if time.time() - start_time > timeout:
            logging.error({'action': '_install_new_database',
                           'message': 'timeout', 'status': 'error'})
            # Leave node up long enough to diagnose
            time.sleep(30)
            exit(1)
        logging.info({'action': '_install_new_database', 'step': '0'})
        sys.stdout.write(self._invoke(
            'mariadb-admin password "%s"' % self.root_password,
            ignore_errors=False, suppress_log=True))
        sys.stdout.write(self._invoke(
            'mariadb-tzinfo-to-sql /usr/share/zoneinfo | '
            'sed "s/Local time zone must be set--see zic manual page/FCTY/" | '
            '%s mysql -u root -p%s' % (mysql_client, self.root_password),
            ignore_errors=False))
        logging.info({'action': '_install_new_database', 'step': '1'})
        sys.stdout.write(self._invoke(
            '%(mysql)s -u root -p%(mysql_root_password)s -e "%(script)s"' % {
                'mysql': mysql_client,
                'mysql_root_password': self.root_password,
                'script': script_setusers},
            ignore_errors=False, suppress_log=False))
        logging.info({'action': '_install_new_database', 'step': '2'})
        time.sleep(60)
        proc.terminate()
        proc.wait()
        logging.info({'action': '_install_new_database', 'status': 'ok'})

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
            self.discovery.get_key(Constants.KEY_WSREP_LOCAL_STATE_COMMENT,
                                   ipv4=ipv4) == 'Synced']
        address = 'gcomm://' + ','.join(sorted(synced))
        log_info = {'action': '_update_cluster_address',
                    'prev_address': self.prev_address,
                    'cluster_address': address}
        if (len(synced) >= self.cluster_size and address != self.prev_address
                and not self.discovery.get_key(
                    Constants.KEY_CLUSTER_UPDATE_TIMER, ipv4=self.my_ipv4)):
            if not self.update_timer_active:
                ttl = (self.ttl_update_timer +
                       random.randrange(self.ttl_update_timer))
                self.discovery.set_key(Constants.KEY_CLUSTER_UPDATE_TIMER, '1',
                                       ttl=ttl)
                self.update_timer_active = True
                logging.info(dict(log_info, **{
                    'status': 'start_timer', 'ttl': ttl}))
            else:
                self.update_timer_active = False
                self._invoke(
                    'mariadb -u root -p%(pw)s -e '
                    '"SET GLOBAL wsrep_cluster_address=\'%(address)s\'";' %
                    {'pw': self.root_password, 'address': address})
                self.prev_address = address
                logging.info(dict(log_info, **{'status': 'ok'}))

    def _peer_reachable(self, ipv4):
        """confirm that a peer can be reached"""

        try:
            self._invoke('ping -c 2 -w 2 %s' % ipv4, ignore_errors=False)
        except AssertionError:
            return False
        return True

    @staticmethod
    def _invoke(command, ignore_errors=True, suppress_log=False):
        """invoke a shell command and return its stdout"""

        log_info = {'action': '_invoke', 'command': re.sub(
            '-u root -p.+ ', '-u root -p[redacted] ', command)}
        log_info['command'] = re.sub(
            "IDENTIFIED BY '.+'",  "IDENTIFIED BY '[redacted]'",
            log_info['command'])
        proc = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE)
        retval = proc.communicate()[0].decode('ascii')
        if proc.returncode == 0:
            if not (suppress_log or 'SHOW STATUS LIKE' in command):
                logging.info(dict(log_info, **{
                    'status': 'ok',
                    'returncode': proc.returncode,
                    'output': retval}))
        else:
            logging.error(dict(log_info, **{
                'status': 'error',
                'returncode': proc.returncode,
                'output': retval}))
            if not ignore_errors:
                raise AssertionError('Command returned %d' % proc.returncode)
        return retval

    @staticmethod
    def _run_background(command):
        """run a command in background"""

        return subprocess.Popen(command, shell=True)


class DiscoveryService(object):

    def __init__(self, nodes, cluster):
        self.ipv4 = socket.gethostbyname(socket.gethostname())
        host, port = nodes[0]
        try:
            self.etcd = etcd3.client(host=host, port=port,
                                     timeout=Constants.ETCD_RETRY_WAIT)
            self.etcd.status()
        except Exception as exc:
            print(f"Etcd client failed: {exc}")
            raise
        self.prefix = Constants.ETCD_PREFIX + '/' + cluster
        self.lock_prefix = '/%s/_locks' % cluster
        try:
            self.ttl = int(os.environ['TTL'])
        except KeyError:
            self.ttl = Constants.DEFAULT_TTL
        self.ttl_dir = Constants.TTL_DIR
        self.locks = {}
        self.cluster = cluster
        logging.info({'action': 'etcd3_init', 'host': host, 'port': port,
                      'prefix': self.prefix, 'cluster': cluster})

    def __del__(self):
        self.delete_key(self.ipv4)

    def set_key(self, keyname, value, my_host=True, ttl=None):
        """set a key under /galera/<cluster>/<my_host>, with a
        lease duration as specified by ttl"""

        ttl = ttl if ttl else Constants.DEFAULT_TTL
        logging.debug({'action': 'set_key', 'keyname': keyname,
                       'value': value, 'ttl': ttl})
        key_path = self.prefix + '/' + self.ipv4 if my_host else self.prefix
        self.etcd.put(key_path, '', lease=self.etcd.lease(ttl))
        self.etcd.put('%(key_path)s/%(keyname)s' %
                      {'key_path': key_path, 'keyname': keyname},
                      str(value), lease=self.etcd.lease(ttl))

    def get_key(self, keyname, ipv4=None):
        """Fetch the key for a given ipv4 node

        returns: scalar value or list of child keys
        """

        log_info = {'action': 'get_key', 'keyname': keyname, 'ipv4': ipv4}
        key_path = self.prefix + '/' + ipv4 if ipv4 else self.prefix
        key_path += '/' + keyname if keyname else ''
        item = self.etcd.get(key_path)
        if item[1]:
            log_info['status'] = 'ok'
            logging.debug(dict(log_info, **{'value': item[0].decode("utf-8")}))
            return item[0].decode("utf-8")
        children = self.etcd.get_prefix(key_path, keys_only=True)
        if children:
            log_info['status'] = 'ok'
            retval = [child[1].key.decode("utf-8").removeprefix(
                self.prefix + '/') for child in children]
            if len(retval) > 0:
                logging.debug(dict(log_info, **{'values': retval}))
                return retval

        logging.debug(dict(log_info, **{
            'status': 'error',
            'message': 'not_found'}))
        return None

    def delete_key(self, keyname, ipv4=None):
        log_info = {'action': 'delete_key', 'keyname': keyname, 'ipv4': ipv4}
        key_path = self.prefix + '/' + ipv4 if ipv4 else self.prefix
        key_path += '/' + keyname if keyname else ''
        ret = self.etcd.delete_prefix(key_path)
        if ret:
            logging.debug(dict(log_info, **{'status': 'ok'}))
        else:
            logging.debug(dict(log_info, **{
                'status': 'error',
                'message': 'not_found'}))

    def get_key_recursive(self, keyname, ipv4=None):
        """Fetch all keys under the given node """

        retval = {meta.key.decode('utf-8').removeprefix(
            self.prefix + '/' + (ipv4 + '/' if ipv4 else '')):
                val.decode('utf-8')
                for val, meta in self.etcd.get_prefix(
                        self.prefix + '/' + ipv4 +
                        ('/' + keyname if keyname else ''))}
        logging.debug({'action': 'get_key_recursive',
                       'keyname': keyname, 'ipv4': ipv4,
                       'retval': retval})
        return retval

    def acquire_lock(self, lock_name, ttl=Constants.DEFAULT_TTL):
        """acquire cluster lock - used upon electing leader"""

        logging.info({'action': 'acquire_lock',
                      'lock_name': lock_name, 'ttl': ttl})
        self.locks[lock_name] = self.etcd.lock(self.lock_prefix + lock_name,
                                               ttl=ttl)
        # TODO: make this an atomic mutex with etcd3
        while self.get_key('lock-%s' % lock_name):
            time.sleep(0.25)
        self.set_key('lock-%s' % lock_name, self.ipv4, my_host=False, ttl=ttl)
        self.locks[lock_name].acquire(timeout=2)

    def release_lock(self, lock_name):
        """release cluster lock"""

        logging.info({'action': 'release_lock', 'lock_name': lock_name})
        self.delete_key('lock-%s' % lock_name)
        self.locks[lock_name].release()


class LoggingDictFormatter(logging.Formatter):
    def format(self, record):
        if type(record.msg) is dict:
            record.msg = self._dict_to_str(record.msg)
        return super(LoggingDictFormatter, self).format(record)

    @staticmethod
    def _dict_to_str(values):
        """Convert a dict to string key1=val key2=val ... """
        return ' '.join(sorted(['%s=%s' % (key, str(val).strip())
                                for key, val in values.items()]))


def setup_logging(level=logging.INFO, output=sys.stdout):
    """For Docker, send logging to stdout"""

    logger = logging.getLogger()
    handler = logging.StreamHandler(output)
    handler.setFormatter(LoggingDictFormatter(
        '%(asctime)s %(levelname)s %(message)s', '%Y-%m-%d %H:%M:%S'))
    logger.setLevel(level)
    logger.addHandler(handler)


def main():
    level = logging.INFO
    if 'LOG_LEVEL' in os.environ:
        if os.environ['LOG_LEVEL'].lower() == 'debug':
            level = logging.DEBUG
        elif os.environ['LOG_LEVEL'].lower() != 'info':
            logging.error({'action': 'main',
                           'level': os.environ['LOG_LEVEL'],
                           'message': 'invalid log_level'})
    setup_logging(level=level)
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
                       'message': str(ex)})
        exit(1)

    if cluster.join:
        cluster.start_database(cluster_address=cluster.join)

    elif all(status == Constants.STATUS_NEW for status in peers.values()):
        # No data on any node: safe to install new cluster
        first_node = sorted(peers.keys())[0]
        cluster.start(first_node, initial_state=Constants.STATUS_INSTALL,
                      cluster_address=first_node, install_ok=True)

    elif (Constants.STATUS_OK in peers.values() or
          Constants.STATUS_DONOR in peers.values()):
        # At least one instance is synchronized, join them
        cluster.start_database(cluster_address=','.join(
            sorted([peer for peer, status in peers.items()
                    if status in (Constants.STATUS_OK,
                                  Constants.STATUS_DONOR)])))

    elif (cluster.health == Constants.STATUS_INIT and
          list(peers.values()).count(Constants.STATUS_NEW) ==
          cluster.cluster_size - 1):
        # Single instance plus new ones: resume installation on leader
        cluster.start(cluster.my_ipv4)

    else:
        # Cluster is down
        cluster.restart_database(peers.keys())

    while cluster.proc.returncode is None:
        cluster.report_status()
        time.sleep(cluster.discovery.ttl * 0.8)
        cluster.proc.poll()

    logging.error({'action': 'main', 'status': 'failed',
                   'returncode': cluster.proc.returncode})
    time.sleep(30)
    raise AssertionError('MariaDB daemon died (%d)' % cluster.proc.returncode)


if __name__ == '__main__':
    main()
