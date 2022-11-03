MAKEFLAGS += --warn-undefined-variables --jobs=1
SHELL := /bin/bash
ifeq ($(word 1,$(subst ., ,$(MAKE_VERSION))),4)
.SHELLFLAGS := -eu -o pipefail -c
endif
.DEFAULT_GOAL := help
.ONESHELL:



.PHONY: help
help: ## Show this help.
	@grep '.*:.*##' Makefile | grep -v grep | sort | sed 's/:.* ##/:/g' | column -t -s:

re: clean up

up:
	docker compose up

config:
	make init
	make join
	make unseal
	make status

init:
	docker compose exec -e VAULT_FORMAT=json vault1 sh -c 'vault operator init -key-shares 1 -key-threshold 1 | tee /tmp/unseal.json | grep unseal_keys_b64 -A1 | tail -1 | xargs -n1 vault operator unseal'
	docker compose cp vault1:/tmp/unseal.json ./

unseal:
	docker compose ps | grep -v SERVICE | grep vault | awk '{print $$3}' | xargs -I{} -o docker compose exec {} sh -c 'vault operator unseal $(shell jq -r '.unseal_keys_b64[0]' unseal.json)'

join:
	docker compose ps | grep -v SERVICE | grep vault | awk '{print $$3}' | xargs -I{} -o docker compose exec {} sh -c 'vault operator raft join http://10.10.10.10:8200'

status:
	docker compose ps | grep -v SERVICE | grep vault | awk '{print $$3}' | xargs -I{} -o docker compose exec -e VAULT_FORMAT=json {} sh -c 'vault status | jq -c'

sh:
	docker compose exec -e VAULT_TOKEN=$(shell jq .root_token unseal.json -r) vault1 /bin/bash

2:
	docker compose exec -e VAULT_TOKEN=$(shell jq .root_token unseal.json -r) vault2 /bin/bash

list-peers:
	docker compose exec -e VAULT_TOKEN=$(shell jq .root_token unseal.json -r) -e VAULT_ADDR=http://localhost:8200 vault1 watch 'vault operator raft list-peers'

step-down:
	docker compose exec -e VAULT_TOKEN=$(shell jq .root_token unseal.json -r) -e VAULT_ADDR=http://nginx:8200 vault1 vault operator step-down

stress:
	docker compose exec -e VAULT_TOKEN=$(shell jq .root_token unseal.json -r) client bash -c '/usr/bin/bombardier -c 500 -d 10s --header "X-Vault-Token: $$VAULT_TOKEN" http://nginx:8200/v1/auth/token/create -m POST'

client:
	docker compose exec -e VAULT_TOKEN=$(shell jq .root_token unseal.json -r) client bash -c 'while sleep 0.1; do vault token create -ttl 10; done'

shclient:
	docker compose exec -e VAULT_TOKEN=$(shell jq .root_token unseal.json -r) client bash

clean:
	docker compose down --remove-orphans --volumes
