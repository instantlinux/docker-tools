#! /bin/bash

# Look for age of most recently-updated record in SQL table

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
warn=720
crit=2880
db=blacklist
field=updated
format=Date
table=ips
usage="Usage: $0 -H <host> [-u user] [-p password] [-d db]
  [-f field] [-t table] [-F format] [-w warn] [-c crit]

  user/password credentials  [default in ~/.my.cnf]
  warn is age to warn at     [default $warn minutes]
  crit is critical threshold [default $crit minutes]
  db is database name        [default $db]
  field is field name        [default $field]
  table is database table    [default $table]
  format (Date or Unixtime)  [default $format]"

while test -n "$1"; do
  case "$1" in
    -c) crit=$2 ;;
    -w) warn=$2 ;;
    -u) user=-u$2 ;;
    -p) pass=-p$2 ;;
    -d) db=$2 ;;
    -f) field=$2 ;;
    -t) table=$2 ;;
    -F) format=$2 ;;
    -H) host=$2 ;;
    -h) echo "$usage"
	exit $STATE_UNKNOWN ;;
    *)  echo "Unknown argument: $1"
        echo "$usage"
	exit $STATE_UNKNOWN ;;
  esac
  shift 2
done

if [ $format == Date ]; then
  query="MAX($field)"
elif [ $format == Unixtime ]; then
  query="FROM_UNIXTIME(MAX($field))"
else
  echo "Unrecognized format: $format"
  echo "$usage"
  exit $STATE_UNKNOWN
fi
age=$(/usr/bin/mysql $user $pass -h $host -sN $db \
      -e "SELECT TIMESTAMPDIFF(MINUTE, $query, NOW()) FROM $table;")

if [ -z "$age" ] || [ "$age" == "NULL" ]; then 
  echo CRIT: age=$age db=$db table=$table field=$field
  exit $STATE_CRITICAL
elif [ "$age" -lt $warn ]; then 
  echo OK: age=$age db=$db table=$table field=$field
  exit $STATE_OK
elif [ "$age" -lt $crit ]; then 
  echo WARN: age=$age db=$db table=$table field=$field
  exit $STATE_WARNING
fi
echo CRIT: age=$age db=$db
exit $STATE_CRITICAL
