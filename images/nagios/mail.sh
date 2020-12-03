#! /bin/sh
# Simple mail client for ssmtp

usage="Usage: cat msg | $0 [-b bcc] [-c cc] [-r from] [-s <subject>] <recipient> ..."

if [ -n "$NAGIOS_FQDN" ]; then
  hostname=$NAGIOS_FQDN
else
  hostname=$(hostname -f)
fi
[ -z "$USER" ] && USER=nagios
from=$USER@$hostname

while test -n "$1"; do
  case "$1" in
    -b) bcc="$bcc $2" ;;
    -c) cc="$cc $2" ;;
    -r) from=$2 ;;
    -s) subject=$2 ;;
    -h) echo "$usage"
        exit $STATE_UNKNOWN ;;
    *)  to="$to $1"
        shift 1
        continue ;;
  esac
  shift 2
done

MSG=$(mktemp)
echo "To: $(echo $to|tr ' ' ,)" > $MSG
[ -n "$cc" ] && echo "Cc: $(echo $cc|tr ' ', )" >> $MSG
[ -n "$subject" ] && echo "Subject: $subject" >> $MSG
echo "Message-Id: <$(head -c16 </dev/urandom|xxd -p|xargs)@$hostname>" >> $MSG
echo "Date: $(date)" >> $MSG
[ -n "$from" ] && echo "From: $from" >> $MSG
echo >> $MSG
cat <&0 >> $MSG

cat $MSG |/usr/sbin/ssmtp $to $cc $bcc
ret=$?
rm $MSG
exit $ret
