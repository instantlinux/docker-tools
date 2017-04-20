SERVERS = mckinley.ci.net vinson.ci.net denali.ci.net
CLIENTS = transcend.ci.net portainer

default: $(SERVERS) $(CLIENTS)

$(SERVERS): flake8
	./gencerts.py -v --host-name=$@ --client-ip=10.0.0.26 \
	  --client-ip=192.168.2.48 --client-ip=192.168.2.64 \
          --subj-city='San Francisco' --subj-state='CA' \
	  --subj-country='US' --subj-org='InstantLinux.Net'

$(CLIENTS):
	./gencerts.py -vv --client-name=$@ 

flake8:
	@flake8 .
