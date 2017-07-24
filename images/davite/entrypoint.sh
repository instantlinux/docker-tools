#! /bin/bash

APACHEDIR=/usr/local/apache2
DATADIR=/var/adm/DaVite_Data
CGI=$APACHEDIR/cgi-bin/DaVite.cgi

if [ ! -f /etc/timezone ] && [ ! -z "$TZ" ]; then
  # At first startup, set timezone
  apk add --update tzdata
  cp /usr/share/zoneinfo/$TZ /etc/localtime
  echo $TZ >/etc/timezone
fi

if [ ! -d $DATADIR/Events ]; then
 mkdir $DATADIR/Events
 chown daemon $DATADIR $DATADIR/Events
fi

sed -i -e "s:{{ DATADIR }}:$DATADIR:" \
       -e "s/{{ HOSTNAME }}/$HOSTNAME/" \
       -e "s/{{ SCHEME }}/$SCHEME/" \
       -e "s/{{ SMTP_SMARTHOST }}/$SMTP_SMARTHOST/" \
       -e "s/{{ SMTP_PORT }}/$SMTP_PORT/" \
       -e "s:{{ SRCDIR }}:$APACHEDIR/htdocs/davite:" \
       -e "s/{{ TCP_PORT }}/$TCP_PORT/" \
       -e "s:{{ URL_PATH }}:$URL_PATH:" $CGI

cat >>$APACHEDIR/conf/httpd.conf <<EOF
LoadModule cgi_module modules/mod_cgi.so
LoadModule actions_module modules/mod_actions.so
<Directory "$APACHEDIR/htdocs/davite">
    Options MultiViews                                                  
    AllowOverride None
</Directory>
EOF

httpd-foreground
