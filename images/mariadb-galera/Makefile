include ../../lib/build/Makefile.docker_image

test: pytest

pytest: test_requirements
	@echo "Running pytest unit tests"
	cd $(SRC) && \
	export PYTHONPATH=. && \
	(. $(VDIR)/bin/activate ; \
	py.test $(XARGS) ../tests/unittests/ \
	 --junitxml=../tests/unittests/results.xml \
	 --cov-report html \
	 --cov-report xml \
	 --cov-report term-missing \
	 --cov .)
