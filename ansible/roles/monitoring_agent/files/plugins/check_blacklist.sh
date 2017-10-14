#! /bin/bash

# Look for most age of most recently-updated record in blacklist table

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
warn=720
crit=2880
usage1="Usage: $0 -H <host> -u user -d db -p password [-w <warn>] [-c <crit>]"
usage2="<warn> is age to warn at.  Default is $warn minutes."
usage3="<crit> is critical threshold.  Default is $crit minutes."

exitstatus=$STATE_WARNING #default
while test -n "$1"; do
  case "$1" in
    -c)
	crit=$2
	shift
	;;
    -w)
	warn=$2
	shift
	;;
    -u)
	user=$2
	shift
	;;
    -d)
	db=$2
	shift
	;;
    -p)
	pass=$2
	shift
	;;
    -H)
	host=$2
	shift
	;;
    -h)
	echo $usage1;
	echo 
	echo $usage2;
	echo $usage3;
	exit $STATE_UNKNOWN
	;;
    *)
	echo "Unknown argument: $1"
	echo $usage1;
	echo 
	echo $usage2;
	echo $usage3;
	exit $STATE_UNKNOWN
	;;
  esac
  shift
done

age=$(/usr/bin/mysql -u $user -p$pass -h $host -sN $db \
      -e 'SELECT ROUND((NOW() - MAX(updated))/60) FROM ips;')

echo -n "$host:$db age=$age "

# if null, critical
if [ "$age" == "NULL" ]; then 
  echo CRIT
  exit $STATE_CRITICAL;
fi

if [ "$age" -ge $warn ]; then 
  if [ "$age" -lt $crit ]; then 
    echo WARN
    exit $STATE_WARNING;
  fi
fi

if [ "$age" -ge $crit ]; then 
  echo CRIT
  exit $STATE_CRITICAL;
fi

if [ "$age" -lt $warn ]; then 
  echo OK
  exit $STATE_OK;
fi
