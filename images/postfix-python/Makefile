include ../../lib/build/Makefile.docker_image

src/honeypot-ip.py: ../blacklist/src/honeypot-ip.py
	@mkdir -p src
	@cp $< $@

analysis: src/honeypot-ip.py flake8
	  @echo "Running static analysis"

