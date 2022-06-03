#!make

CTR_REGISTRY ?= flomesh
CTR_TAG      ?= latest

DOCKER_BUILDX_OUTPUT ?= type=registry

ARCH_MAP_x86_64 := amd64
ARCH_MAP_arm64 := arm64
ARCH_MAP_aarch64 := arm64

BUILDARCH := $(ARCH_MAP_$(shell uname -m))
BUILDOS := $(shell uname -s | tr '[:upper:]' '[:lower:]')

check-env:
ifndef CTR_REGISTRY
	$(error CTR_REGISTRY environment variable is not defined; see the .env.example file for more information; then source .env)
endif
ifndef CTR_TAG
	$(error CTR_TAG environment variable is not defined; see the .env.example file for more information; then source .env)
endif

.PHONY: kind-up
kind-up:
	./scripts/kind-with-registry.sh

.PHONY: kind-reset
kind-reset:
	kind delete cluster --name osm

.PHONY: install-osm-cli
install-osm-cli:
	./scripts/install-osm-cli.sh ${BUILDARCH} ${BUILDOS}

.env:
	cp .env.example .env

.PHONY: kind-demo
kind-demo: export CTR_REGISTRY=flomesh
kind-demo: .env kind-up
	./demo/run-osm-demo.sh

