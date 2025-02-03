#!/bin/sh
# Nagios plugin - simpler ping that doesn't leave zombie processes
#  This exists only because in December 2020, after upgrading the OS
#  distro, nagios, its plugins and *everything else*, the check_ping
#  command started leaving 1000+ zombies daily. This shell script doesn't.

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
warn=100,10%
crit=500,50%
packets=5
pingcmd=ping
interface=br0

usage="Usage: $0 [-H host] [-w warn] [-c crit] [-p packets]
  -H, --hostname=<host>  Hostname or IP address
  -c, --critical=<n>,<%> Crit threshold [$crit]
  -w, --warning=<n>,<%>  Warn threshold [$warn]
  -I, --interface=<int>  Interface (for ipv6) [$interface]
  -p, --packets=n        Number of packets [$packets]
  -4, --use-ipv4         Use IPv4
  -6, --use-ipv6         Use IPv6 (ping6)

  warn/crit expressed as <ms timeout>,<% dropped>"
while test -n "$1"; do
  case "$1" in
    --critical|-c) crit=$2 ;;
    --warning|-w)  warn=$2 ;;
    --hostname|-H) host=$2 ;;
    --packets|-p)  packets=$2 ;;
    --use-ipv4|-4) pingcmd=ping ; shift 1 ; continue ;;
    --use-ipv6|-6) pingcmd=ping6; shift 1 ; continue ;;
    --help|-h) echo "$usage"
	exit $STATE_UNKNOWN ;;
    *)  echo "Unknown argument: $1"
        echo "$usage"
	exit $STATE_UNKNOWN ;;
  esac
  shift 2
done

thresh_parse() {
  ms=$(echo $1 | cut -d, -f 1)
  pct=$(echo $1 | cut -d, -f 2 | cut -d% -f 1)
}

thresh_parse $crit
crit_sec=$(( $(printf %.0f $ms) / 1000 ))
crit_ms=$ms
crit_pct=$(printf %.0f $pct)
thresh_parse $warn
warn_sec=$(( $(printf %.0f $ms) / 1000 ))
warn_ms=$ms
warn_pct=$(printf %.0f $pct)

[ $crit_sec -lt $packets ] && crit_sec=$packets
[ $pingcmd = ping6 ] && pingcmd="$pingcmd -I $interface"

output=$(mktemp)
/bin/$pingcmd -c $packets -w $crit_sec $host > $output
ret=$?
status=$(grep -E 'transmitted|round-trip|rtt' $output)
rta=$(grep -E 'round-trip|rtt' $output |cut -d= -f 2|cut -d / -f 2)
loss=$(echo $status | grep -oP '[0-9]{1,3}%'|cut -d% -f 1)
rm $output
if [ $ret != 0 ]; then
  echo "CRIT: $status"
  exit $STATE_CRITICAL
fi
if [ "$loss" = "" ]; then
  echo "UNKNOWN: no loss % found: $status"
  exit $STATE_UNKNOWN
elif [ $loss -ge $crit_pct ]; then
  echo "CRIT: loss ($loss%): $status"
  exit $STATE_CRITICAL
elif [ $loss -ge $warn_pct ]; then
  echo "WARN: loss ($loss%): $status"
  exit $STATE_WARNING
fi
if [ "$rta" = "" ]; then
  echo "UNKNOWN: no rta found: $status"
  exit $STATE_UNKNOWN
elif echo $crit_ms - $rta | bc | grep -q "-"; then
  echo "CRIT: rtt avg ($rta): $status"
  exit $STATE_CRITICAL
elif echo $warn_ms - $rta | bc | grep -q "-"; then
  echo "WARN: rtt avg ($rta): $status"
  exit $STATE_WARNING
fi    
echo "OK: $status"
exit $STATE_OK
