VENV ?= python_env
VDIR ?= $(PWD)/$(VENV)

test: test_requirements
	ansible-lint *.yml

PLAYBOOKS = $(basename $(wildcard *.yml))
$(PLAYBOOKS):
	ansible-playbook $(@F).yml

.PHONY: test test_requirements $(PLAYBOOKS)

python_env: $(VDIR)/bin/python

test_requirements: python_env
	@echo "Installing test requirements"
	(. $(VDIR)/bin/activate && \
	 pip install -r requirements/common.txt)

$(VDIR)/bin/python:
	@echo "Creating virtual environment"
	virtualenv --system-site-packages $(VENV)
