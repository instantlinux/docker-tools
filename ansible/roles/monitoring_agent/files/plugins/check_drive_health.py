#!/usr/bin/env python3
"""check_drive_health

Nagios plugin to check health of SSD and magnetic drives. Examines
SMART attributes and software-RAID status. As a drive ages,
reallocated sector counts may be recorded in SMART attributes - this
plugin provides a way to define per-drive tolerance for nonzero values
reported in SMART attributes, and to warn when new events occur.

Dependencies: python >= 3.6, smartmontools >=7.0, click >= 6.0, mdstat >= 1.0.4

Usage example:

  $ check_drive_health.py -w 45 -e drive_tolerate.yaml
  /dev/sda OK: temp=38 serial=7E3020001587 cap=0.064T
  /dev/sdb OK: temp=42 serial=1632137A883D cap=1.050T
  RAID OK: 1 array clean

Error-list example:
  Top-level key in drive_tolerate.yaml is drive serial number, second-level
  keys are attribute names as reported by smartctl -A:

  ---
  PN1338P4J8MT49:
    Reallocated_Sector_Ct: 20
    Reallocated_Event_Count: 45

Setup:
  # install smartmontools package if 7.1 is available in distro
  #  or download smartmontools-7.1.tar.gz from
  # https://sourceforge.net/projects/smartmontools/files/smartmontools/7.1/
  tar xf smartmontools.7.1.tar.gz
  cd smartmontools-7.1 && ./configure && make install
  pip3 install click==7.1.2 mdstat==1.0.4

  Grant this plugin sudo (for smartctl) with an entry in /etc/sudoers.d:
  nagios ALL=NOPASSWD:	/usr/local/lib/nagios/check_drive_health.py

created 25 oct 2020 by richb at instantlinux.net
homepage https://github.com/instantlinux/docker-tools - find this plugin
  under ansible monitoring_agent role
license Apache-2.0
"""

import click
import json
import mdstat
import os
import sys
import yaml

__version__ = '0.1.1'

STATUS_OK = 0
STATUS_WARN = 1
STATUS_CRIT = 2
STATUS_UNK = 3
SMART_ATTR_CHECKS = {
    5: dict(name='Reallocated_Sector_Ct', level=STATUS_WARN),
    196: dict(name='Reallocated_Event_Count', level=STATUS_WARN),
    197: dict(name='Current_Pending_Sector', level=STATUS_WARN),
    198: dict(name='Offline_Uncorrectable', level=STATUS_CRIT)}


@click.command(context_settings=dict(help_option_names=['-h', '--help']))
@click.version_option(version=__version__,)
@click.option('--device', '-d', default=['all'],
              type=str, multiple=True,
              help='Device to check - /dev/xxx or all [default: all]')
@click.option('--error-list', '-e',
              type=click.File('r'),
              help='Expected errors: list of known problems indexed by '
                   'device serial number, in YAML format')
@click.option('--raid/--no-raid', default=True,
              help='Examine RAID devices found in /proc/mdstat [true]')
@click.option('--warn-temp', '-w', default=50,
              type=int,
              help='Temperature warning threshold [50]')
@click.option('--crit-temp', '-c', default=65,
              type=int,
              help='Temperature critical threshold [65]')
@click.option('--warn-spare', default=50,
              type=int,
              help='Spare-percentage warning threshold for nvme [50]')
def main(device, error_list, raid, warn_temp, crit_temp, warn_spare):
    if 'all' in device:
        device = [item['name'] for item in
                  json.load(os.popen('lsblk -dJ -e 7'))['blockdevices']]
    error_items = yaml.safe_load(error_list) if error_list else {}
    retval = STATUS_OK
    messages = []
    for drive in device:
        status, message = check_smart(drive, error_items, warn_temp,
                                      crit_temp, warn_spare)
        retval = max(retval, status)
        messages.append(message)
    if raid and 'active' in open('/proc/mdstat', 'r').read():
        status, message = check_raid()
        retval = max(retval, status)
        messages.append(message)
    print('\n'.join(messages))
    exit(retval)


def check_smart(drive, error_items, warn_temp, crit_temp, warn_spare):
    """Read SMART attributes for a drive, looking for values above
    0 or as defined in error_items

    Returns:
      tuple(int, str) - status and message
    """
    if drive[:5] != '/dev/':
        drive = '/dev/%s' % drive
    try:
        smart = json.load(os.popen('smartctl -AHij %s' % drive))
    except json.JSONDecodeError:
        sys.stderr.write('ERR: Please upgrade smartctl to 7.0 or newer\n')
        exit(STATUS_UNK)
    if dot_get(smart, 'smartctl.exit_status') != 0:
        return STATUS_UNK, 'UNK(%s): %s' % (drive, dot_get(
            smart, 'smartctl.messages', [{}])[0].get('string'))
    status, message = STATUS_OK, ''
    attribs = dot_get(smart, 'ata_smart_attributes.table')
    capacity = dot_get(smart, 'user_capacity.bytes')
    nvme_log = smart.get('nvme_smart_health_information_log')
    serial_num = smart.get('serial_number')
    temperature = dot_get(smart, 'temperature.current')
    tolerated = error_items.get(serial_num, {})

    if not dot_get(smart, 'smart_status.passed'):
        return STATUS_CRIT, 'CRIT: serial=%s smart_status not OK' % serial_num
    if temperature > crit_temp:
        return STATUS_CRIT, 'CRIT: %s serial=%s temp=%d exceeds threshold' % (
            drive, serial_num, temperature)
    elif temperature > warn_temp:
        status = STATUS_WARN
        message = 'WARN: %s serial=%s, temp=%d exceeds threshold' % (
            drive, serial_num, temperature)
    if nvme_log:
        spare_threshold = max(nvme_log.get('available_spare_threshold', 0),
                              warn_spare)
        available_spare = nvme_log.get('available_spare', 100)
        if available_spare < spare_threshold:
            status = STATUS_WARN
            message = 'WARN: %s serial=%s low available_spare=%d' % (
                drive, serial_num, available_spare)
    if attribs:
        values = {}
        for item in attribs:
            if item.get('id') in SMART_ATTR_CHECKS.keys():
                values[item['name']] = dict(
                    val=dot_get(item, 'raw.value'),
                    level=SMART_ATTR_CHECKS[item['id']]['level'])
        for key, item in values.items():
            if item['val'] > tolerated.get(key, 0):
                status = item['level']
                message = '%s: %s serial=%s %s: %d' % (
                    'CRIT' if status == STATUS_CRIT else 'WARN',
                    drive, serial_num, key, item['val'])
    if status == STATUS_OK:
        message = '%s OK: temp=%d serial=%s cap=%.3fT' % (
            drive, temperature, serial_num, capacity / 1e12)
    return status, message


def check_raid():
    """Check all RAID devices seen in /proc/mdstat

    Returns:
      tuple(int, str) - status and message
    """
    status, message, count = STATUS_OK, '', 0
    for array, state in mdstat.parse().get('devices', {}).items():
        for element, values in state.get('disks').items():
            if values.get('faulty'):
                return STATUS_CRIT, 'CRIT: /dev/%s element=%s faulty' % (
                    array, element)
        # unless monthly checkarray is running, warn if out of sync
        action = open('/sys/block/%s/md/sync_action' % array, 'r').read()
        if (False in dot_get(state, 'status.synced') or
                state.get('resync')) and action.strip() != 'check':
            status = STATUS_WARN
            message = 'WARN: /dev/%s resync progress=%s finish=%s' % (
                array, dot_get(state, 'resync.progress'),
                dot_get(state, 'resync.finish'))
        count += 1
    if status == STATUS_OK:
        message = 'RAID OK: %d array%s clean' % (count, 's'[:count - 1])
    return status, message


def dot_get(_dict, path, default=None):
    """Fetch item from nested dict; path is a dot-delimited key into
    the dictionary

    Returns: obj if found, specified default otherwise
    """
    for key in path.split('.'):
        try:
            _dict = _dict[key]
        except KeyError:
            return default
    return _dict


if __name__ == "__main__":
    main()
