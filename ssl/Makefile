DOM = ci.net
DOM2 = instantlinux.net
WEB_HOSTS = monitor.$(DOM) nexus.$(DOM2) oidc.$(DOM2) redmond.$(DOM)
DOCKER_HOSTS = swarm01.$(DOM) mckinley.$(DOM) vinson.$(DOM) denali.$(DOM)
DOCKER_CLIENTS = administrator portainer
CERT_INFO = --subj-city='San Francisco' --subj-state=CA \
	  --subj-country=US --subj-org=InstantLinux.Net

default: docker_hosts docker_clients

web_hosts: $(WEB_HOSTS)
docker_hosts: $(DOCKER_HOSTS)
docker_clients: $(DOCKER_CLIENTS)

$(DOCKER_HOSTS): flake8
	./gencerts.py -v --host-name=$@ --client-ip=10.0.0.26 \
	  --client-ip=192.168.2.48 --client-ip=192.168.2.64 \
          --client-ip=127.0.0.1 $(CERT_INFO)

$(DOCKER_CLIENTS):
	./gencerts.py -vv --client-name=$@ 


$(WEB_HOSTS): flake8
	./gencerts.py -v --host-name=$@ --client-name=$@ --directory=~/ssl \
	--ca-file=instantlinux-ca2 --cn-root='InstantLinux CA 2' \
        --ca-subject='InstantLinux Root' --days=9125 $(CERT_INFO)

flake8:
	@flake8 .
