INV = inventory.yml
PLAYBOOK = site.yml
OPTS =
TAGS =

.PHONY: all help deploy ping dry-run install lint

# Default target runs help to prevent accidental deploys
all: help

## deploy    : Run the playbook (usage: make deploy TAGS=tagname)
deploy:
	ansible-playbook -i $(INV) $(PLAYBOOK) $(OPTS) $(if $(TAGS),--tags $(TAGS))

## ping      : Ping all hosts to check connectivity
ping:
	ansible -i $(INV) all -m ping

## dry-run   : Run in check mode with diff to see changes without applying them
dry-run:
	ansible-playbook -i $(INV) $(PLAYBOOK) $(OPTS) $(if $(TAGS),--tags $(TAGS)) --check --diff

## install   : Install roles from requirements.yml
install:
	ansible-galaxy install -r requirements.yml

## lint      : Check syntax and style using ansible-lint
lint:
	ansible-playbook -i $(INV) $(PLAYBOOK) --syntax-check
	@echo "Syntax check passed. If you have ansible-lint installed, running it now..."
	-ansible-lint $(PLAYBOOK)

## help      : Show this help message
help:
	@echo "Usage: make [target] [variables]"
	@echo ""
	@echo "Targets:"
	@fgrep "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/## //'
