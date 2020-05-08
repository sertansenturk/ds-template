SHELL := /bin/bash
.DEFAULT_GOAL := default
.PHONY: \
	help default cut \
	install test \
	clean clean-test clean-clean-$(VENV_NAME) clean-$(DOCS_FOLDER) \
	sphinx-build sphinx-quickstart sphinx-html \
	debug-travis

HELP_PADDING = 28
bold := $(shell tput bold)
sgr0 := $(shell tput sgr0)
padded_str := %-$(HELP_PADDING)s
pretty_command := $(bold)$(padded_str)$(sgr0)

VENV_INTERP = python3
VENV_NAME ?= venv

BUILDKIT = 1
DOCKER_USERNAME = sertansenturk

MAKEFILE_DIR = $(dir $(realpath $(firstword $(MAKEFILE_LIST))))
VERSION := $(shell cat VERSION)
AUTHORS := $(shell cut -f1 AUTHORS | awk 1 ORS=', ' | head -c -2)

CUT_BASE_FOLDER = ..
CUT_OPTS := --output-dir $(CUT_BASE_FOLDER)

TEST_BASE_FOLDER = .
TEST_FOLDER = test-project

DOCS_FOLDER = docs
SPHINX_VERSION = 3.0.3
SPHINX_IMAGE = $(DOCKER_USERNAME)/sphinx:$(SPHINX_VERSION)

TRAVIS_JOB =
TRAVIS_TOKEN =

help:
	@printf "======= General ======\n"
	@printf "$(pretty_command): alias of \"make cut\" (see below)\n" \(default\)
	@printf "$(pretty_command): cut a new project\n" cut
	@printf "$(padded_str)CUT_OPTS, cookiecutter options (default: $(CUT_OPTS))\n"
	@printf "$(pretty_command): run cookiecutter and template tests\n" test
	@printf "\n"
	@printf "======= Setup =======\n"
	@printf "$(pretty_command): create a python virtualenv called $(VENV_NAME)\n" $(VENV_NAME)
	@printf "$(padded_str)VENV_INTERP, python interpreter (default: $(VENV_INTERP))\n"
	@printf "$(pretty_command): install cookiecutter in the virtualenv\n" install
	@printf "\n"
	@printf "======= Cleanup ======\n"
	@printf "$(pretty_command): remove everything described below\n" clean
	@printf "$(pretty_command): remove the test project folder\n" clean-test
	@printf "$(pretty_command): remove the virtualenv\n" clean-$(VENV_NAME)
	@printf "$(pretty_command): remove the sphinx documentation\n" clean-$(DOCS_FOLDER)
	@printf "\n"
	@printf "======= Documentation ======\n"
	@printf "$(pretty_command): builds sphinx docker image\n" sphinx-build
	@printf "$(pretty_command): \"quickstarts\" sphinx documentation\n" sphinx-quickstart
	@printf "$(pretty_command): builds sphinx html docs\n" sphinx-html	
	@printf "\n"
	@printf "========= Misc =======\n"
	@printf "$(pretty_command): send a job debug request to travis\n" debug-travis
	@printf "$(padded_str)TRAVIS_TOKEN, travis api token (default: $(TRAVIS_TOKEN))\n"
	@printf "$(padded_str)TRAVIS_JOB, travis job id (default: $(TRAVIS_JOB))\n"

default: cut

$(VENV_NAME):
	virtualenv -p $(VENV_INTERP) $(VENV_NAME)

install: $(VENV_NAME)
	source $(VENV_NAME)/bin/activate ; \
	pip install --upgrade pip ; \
	pip install cookiecutter

cut: install
	source $(VENV_NAME)/bin/activate ; \
	cookiecutter ./ $(CUT_OPTS)

test: CUT_OPTS:=--no-input --output-dir $(TEST_BASE_FOLDER) repo_slug=$(TEST_FOLDER)
test: clean-test cut
	cd $(TEST_FOLDER) ; \
	make test ; \
	make tox
	$(MAKE) clean-test

clean: clean-$(VENV_NAME) clean-test clean-$(DOCS_FOLDER)

clean-test:
	rm -rf $(TEST_FOLDER)

clean-$(VENV_NAME):
	rm -rf $(VENV_NAME)

clean-$(DOCS_FOLDER):
	rm -rf $(DOCS_FOLDER)

sphinx-build:
	DOCKER_BUILDKIT=${BUILDKIT} \
	docker build . \
		-f ./docker/sphinx/Dockerfile \
		-t $(SPHINX_IMAGE)

sphinx-quickstart: sphinx-build
	mkdir -p $(DOCS_FOLDER)
	docker run -it --rm -v $(MAKEFILE_DIR)$(DOCS_FOLDER):/docs $(SPHINX_IMAGE) sphinx-quickstart \
		-q \
		-p cookiecutter-ds-docker \
		-a "$(AUTHORS)" \
		-v $(VERSION)

sphinx-html: sphinx-build
	docker run -it --rm -v $(MAKEFILE_DIR)$(DOCS_FOLDER):/docs $(SPHINX_IMAGE) make html

debug-travis:
	curl -s -X POST \
		-H "Content-Type: application/json" \
		-H "Accept: application/json" -H "Travis-API-Version: 3" \
		-H "Authorization: token $(TRAVIS_TOKEN)" \
		-d '{ "quiet": true }' \
		https://api.travis-ci.com/job/$(TRAVIS_JOB)/debug
