VENV      ?= python_env
VDIR      ?= $(HOME)/$(VENV)
INVENTORY ?= hosts

test: test_requirements
	ansible-lint *.yml

PLAYBOOKS = $(basename $(wildcard *.yml))
$(PLAYBOOKS):
	ansible-playbook -i $(INVENTORY) $(@F).yml

.PHONY: test test_requirements $(PLAYBOOKS)

python_env: $(VDIR)/bin/python

test_requirements: python_env
	@echo "Installing test requirements"
	(. $(VDIR)/bin/activate && \
	 pip install --break-system-packages -r requirements.txt)

$(VDIR)/bin/python:
	@echo "Creating virtual environment"
	python3 -m venv --system-site-packages $(VDIR)
