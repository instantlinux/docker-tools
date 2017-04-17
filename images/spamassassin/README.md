## spamassassin

This image includes pyzor, razor2 and dcc (with proper initialization of
razor2 upon container start). The rules update can be scheduled to run at an
interval specified in cron.

To add local rules, create a rules file for /etc/mail/spamassassin/local.cf
and map that file into the container. To ensure that updated rules survive
container restart, make sure the /var/lib/spamassassin home directory is
mounted to a named volume. See the swarm-stack.yml Docker compose
file here for an example.
