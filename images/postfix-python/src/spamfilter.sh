#!/bin/sh
# AGPLv3 http://www.gnu.org/licenses/agpl.txt

# Shell variables
USERNAME=spamfilter
source /home/$USERNAME/.profile

# Variables
SENDMAIL="/usr/sbin/sendmail -i"
EGREP=/bin/egrep
SPAMC="/usr/bin/spamc -d $SPAMC_HOST"
QUARANTINE=/var/spool/postfix/quarantine

# Exit codes from <sysexits.h>
EX_UNAVAILABLE=69

# Number of *'s in X-Spam-level header needed to sideline message:
# (Eg. Score of 5.5 = "*****" )
SPAMLIMIT=$SPAMLIMIT

# Clean up when done or when aborting.
trap "rm -f /var/tmp/out.$$" 0 1 2 3 15

# Look for honeypot
cat > /var/tmp/raw.$$
cat /var/tmp/raw.$$ | /usr/local/bin/honeypot-ip.py \
  --db-config=/home/$USERNAME/.my.cnf \
  --db-user=$DB_USER --honeypot="$HONEYPOT_ADDRS" \
  --relay="$INBOUND_RELAY" --cidr-min-size=$CIDR_MIN_SIZE
# Pipe message to spamc
cat /var/tmp/raw.$$ | $SPAMC -u $USERNAME | sed 's/^\.$/../' > /var/tmp/out.$$
rm /var/tmp/raw.$$

# Are there more than $SPAMLIMIT stars in X-Spam-Level header? :
if $EGREP -q "^X-Spam-Level: \*{$SPAMLIMIT,}" < /var/tmp/out.$$
then
  QDIR=$QUARANTINE/`date +%Y%m%d`
  [ -d $QDIR ] || mkdir $QDIR

  # (Temp) Move high scoring messages to quarantine dir so
  # a human can look at them later:
  mv /var/tmp/out.$$ $QDIR/`date +%m-%d_%R`-$$

  # (Once we are done debugging): Delete the message
  # rm -f /var/tmp/out.$$
else
  $SENDMAIL "$@" < /var/tmp/out.$$
fi

# Postfix returns the exit status of the Postfix sendmail command.
exit $?
