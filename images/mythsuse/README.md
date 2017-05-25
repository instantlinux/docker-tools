## mythsuse

The MythTV backend built under OpenSuSE.

### Usage

To run mythtv-setup, invoke an exec shell and enable sshd with xauth:
~~~
/usr/sbin/sshd-gen-keys-start
/usr/sbin/sshd
~~~
Then invoke "ssh -X" to the IP address of the container, as user mythtv
(same password) to run mythtv-setup in the normal way.
### Variables
| Variable | Default | Description |
| -------- | ------- | ----------- |
| APACHE_LOCK_DIR | /var/lock/apache2 | |
| APACHE_LOG_DIR | /var/log/apache2 | |
| APACHE_PID_FILE | /var/run/apache2.pid | |
| APACHE_RUN_GROUP | www-data | |
| APACHE_RUN_USER | www-data | |
| HOME | /root | |
| LANG | en_US.UTF-8 | |
| LANGUAGE | en_US:en | |
| LC_ALL | en_US.UTF-8 | |
| TERM | xterm | |
