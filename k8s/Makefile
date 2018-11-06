ACTION ?= apply
STACKS = $(basename $(wildcard *.yaml))

db00: CLUSTER_NAME = db00
db02: CLUSTER_NAME = db02

all: $(STACKS)

$(STACKS)::
	@echo --Deploying $(@F)--
	@CLUSTER_NAME=$(CLUSTER_NAME) \
	 SERVICE_NAME=$(@F) \
	  envsubst < $(@F).yaml | kubectl $(ACTION) -f -
