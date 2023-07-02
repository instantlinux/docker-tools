# Standard Makefile for python application
#   created by rbraun @ splunk 7-Apr-2017

SRC  ?= src
VENV ?= python_env
VDIR ?= $(PWD)/$(VENV)

analysis: flake8
	@echo "Running static analysis"

test: pytest

test_functional:
	@echo "Running functional verification of running image"
	@echo "--TODO not yet implemented--"

flake8: test_requirements
	@echo "Running flake8 code analysis"
	(. $(VDIR)/bin/activate ; flake8 --exclude=python_env .)

python_env: $(VDIR)/bin/python

test_requirements: python_env
	@echo "Installing test requirements"
	(. $(VDIR)/bin/activate && \
	 pip install -r requirements/test.txt -r requirements/common.txt)

$(VDIR)/bin/python:
	@echo "Creating virtual environment"
	virtualenv --system-site-packages $(VDIR)

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

clean:
	@echo "Cleaning out generated files"
	@rm -rf ./$(SRC)/{.coverage,htmlcov,coverage.xml}
	@find . -name \*.pyc -exec rm {} \;
	@find . -name \*.log -exec rm {} \;
	@find . -name \*~ -exec rm {} \;
	@find . -name results.xml -exec rm {} \;
	@find . -name __pycache__ -exec rm -fr {} \;
