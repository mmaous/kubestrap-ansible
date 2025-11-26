INV = inventory.yml
PLAYBOOK = site.yml
OPTS =
TAGS =

.PHONY: all
all: deploy

deploy:
	ansible-playbook -i $(INV) $(PLAYBOOK) $(OPTS) $(if $(TAGS),--tags $(TAGS))

ping:
	ansible -i $(INV) all -m ping

dry-run:
	ansible-playbook -i $(INV) $(PLAYBOOK) $(OPTS) $(if $(TAGS),--tags $(TAGS)) --check --diff
