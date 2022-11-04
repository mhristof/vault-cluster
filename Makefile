MAKEFLAGS += --warn-undefined-variables --jobs=1
SHELL := /bin/bash
ifeq ($(word 1,$(subst ., ,$(MAKE_VERSION))),4)
.SHELLFLAGS := -eu -o pipefail -c
endif
.DEFAULT_GOAL := help
.ONESHELL:

HOST := $(shell docker compose ps  | grep vault  | grep running  | shuf -n1 | awk '{print $$3}')
EXEC := docker compose exec -e VAULT_TOKEN=$(shell jq .root_token unseal.json -r) $(HOST)


.PHONY: help
help: ## Show this help.
	@grep '.*:.*##' Makefile | grep -v grep | sort | sed 's/:.* ##/:/g' | column -t -s:

re: clean up ## Recreate the env (clean and up)

up:
	docker compose up

config:
	make init
	make join
	make unseal
	make status

init: ## vault init
	docker compose exec -e VAULT_FORMAT=json vault1 sh -c 'vault operator init -key-shares 1 -key-threshold 1 | tee /tmp/unseal.json | grep unseal_keys_b64 -A1 | tail -1 | xargs -n1 vault operator unseal'
	docker compose cp vault1:/tmp/unseal.json ./

unseal: ## vault unseal all nodes
	docker compose ps | grep -v SERVICE | grep vault | awk '{print $$3}' | xargs -I{} -o docker compose exec {} sh -c 'vault operator unseal $(shell jq -r '.unseal_keys_b64[0]' unseal.json)'

join: ## raft join commands to all nodes
	docker compose ps | grep -v SERVICE | grep vault | awk '{print $$3}' | xargs -I{} -o docker compose exec {} sh -c 'vault operator raft join http://10.10.10.10:8200'

status: ## execute 'vault status' in all nodes
	docker compose ps | grep -v SERVICE | grep vault | awk '{print $$3}' | xargs -I{} -o docker compose exec -e VAULT_FORMAT=json {} sh -c 'vault status | jq -c'

sh: ## spawn a shell to vault cluster
	docker compose exec -e VAULT_TOKEN=$(shell jq .root_token unseal.json -r) $(HOST) /bin/bash

list-peers: ## watch the list-peers output
	docker compose exec -e VAULT_TOKEN=$(shell jq .root_token unseal.json -r) -e VAULT_ADDR=http://localhost:8200 $(HOST) watch 'vault operator raft list-peers'
 
step-down: ## step down current leader
	docker compose exec -e VAULT_TOKEN=$(shell jq .root_token unseal.json -r) -e VAULT_ADDR=http://nginx:8200 $(HOST) vault operator step-down

autopilot:
	$(EXEC) vault operator raft autopilot set-config -cleanup-dead-servers=true -min-quorum=3 -dead-server-last-contact-threshold=10

stress: ## stress test vault by creating tokens
	docker compose exec -e VAULT_TOKEN=$(shell jq .root_token unseal.json -r) client bash -c '/usr/bin/bombardier -d 10s --header "X-Vault-Token: $$VAULT_TOKEN" http://nginx:8200/v1/auth/token/create -m POST'

shclient: ## spawn a shell in the client 
	docker compose exec -e VAULT_TOKEN=$(shell jq .root_token unseal.json -r) client bash

clean:
	docker compose down --remove-orphans --volumes
