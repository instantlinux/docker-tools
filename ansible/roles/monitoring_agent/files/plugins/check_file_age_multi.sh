#!/bin/sh
# NRPE plugin - look for files (as specified by path and wildcard) exceeding
# age threshhold

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
warn=1440
crit=2880
depth=99
usage="Usage: $0 [-P path] [-F files] [-d depth] [-w warn] [-c crit]

  warn / crit time periods are specified as minutes
"
while test -n "$1"; do
  case "$1" in
    -c) crit=$2 ;;
    -w) warn=$2 ;;
    -d) depth=$2 ;;
    -F) files=$2 ;;
    -P) path=$2 ;;
    -h) echo "$usage"
	exit $STATE_UNKNOWN ;;
    *)  echo "Unknown argument: $1"
        echo "$usage"
	exit $STATE_UNKNOWN ;;
  esac
  shift 2
done

output=$(mktemp -u)
cd "$path" || exit $STATE_UNKNOWN
find . -name "$files" -mmin +$crit -maxdepth $depth | sed 's:^\./::' > $output
if [ -s $output ]; then
  echo "CRIT: count=$(cat $output | wc -l) $(cat $output)"
  rm $output
  exit $STATE_CRITICAL
fi
find . -name "$files" -mmin +$warn -maxdepth $depth | sed 's:^\./::' > $output
if [ -s $output ]; then
  echo "WARN: count=$(cat $output | wc -l) $(cat $output)"
  rm $output
  exit $STATE_WARNING
fi
echo "OK: count=$(echo $files | wc -w)"
exit $STATE_OK
