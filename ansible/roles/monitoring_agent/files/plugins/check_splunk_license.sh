#! /bin/bash

# NRPE plugin to evaluate percentage of Splunk license used yesterday

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
warn=50
crit=80
path=/var/log/splunk
usage="Usage: $0 [-P path] [-w warn] [-c crit]

  warn is % to warn at       [default $warn]
  crit is critical threshold [default $crit]
  path is path of license_usage.log [default $path]
"
while test -n "$1"; do
  case "$1" in
    -c) crit=$2 ;;
    -w) warn=$2 ;;
    -P) path=$2 ;;
    -h) echo "$usage"
	exit $STATE_UNKNOWN ;;
    *)  echo "Unknown argument: $1"
        echo "$usage"
	exit $STATE_UNKNOWN ;;
  esac
  shift 2
done

poolsz=$(tail -1 $path/license_usage_summary.log|grep -Po 'poolsz=\K[0-9]+')
if [ $? != 0 ]; then
  echo UNKNOWN: poolsz
  exit $STATE_UNKNOWN
fi
used=$(tail -1 $path/license_usage_summary.log|grep -Po ' b=\K[0-9]+')
if [ $? != 0 ]; then
  echo UNKNOWN: used
  exit $STATE_UNKNOWN
fi

if [ $((used * 100 / poolsz)) -lt $warn ]; then
  echo OK: used=$((used / 1024)) poolsz=$((poolsz / 1024))
  exit $STATE_OK
elif [ $((used * 100 / poolsz)) -lt $crit ]; then
  echo WARN: used=$((used / 1024)) poolsz=$((poolsz / 1024))
  exit $STATE_WARNING
fi
echo CRIT: used=$((used / 1024)) poolsz=$((poolsz / 1024))
exit $STATE_CRITICAL

