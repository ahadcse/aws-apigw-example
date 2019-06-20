#!/usr/bin/env bash

ENVIRONMENT ?= dev
SERVICE ?= aws-apigw-example
AWS_REGION ?= eu-west-1

ARTIFACTS_BUCKET:=artifactory-s3-bucket-name-$(ENVIRONMENT)
ARTIFACTS_PREFIX:=$(SERVICE)

SERVERLESS_STACK_NAME = $(SERVICE)-serveless
IAM_STACK_NAME = $(SERVICE)-iam

SWAGGER_PATH = s3://$(ARTIFACTS_BUCKET)/$(ARTIFACTS_PREFIX)/swagger.yml

NOW = $(shell date)
REPOS = $(shell git config --get remote.origin.url)
REV = $(shell git rev-parse HEAD)

#####################
# DEPLOY IAM
#####################
.PHONY: deploy_iam
deploy_iam:
	@echo "\n------Deploying iam------\n"
	date

	$(eval API := $(shell aws apigateway get-rest-apis --query 'items[?name==`aws-apigw-example`].id' --output text))

	aws cloudformation deploy \
	--template-file cloudformation/iam.yaml  \
	--stack-name $(IAM_STACK_NAME) \
	--capabilities CAPABILITY_NAMED_IAM  \
	--region $(AWS_REGION) \
	--tags Environment=$(ENVIRONMENT) Owner=beam Project=$(SERVICE) \
	--parameter-overrides \
	Service=$(SERVICE) \
	Environment=$(ENVIRONMENT) \
	Api=$(API)

	date
	@echo "\n------Deploy iam DONE------\n"

###################
# PACKAGE RESOURCES
###################
.PHONY: package_serverless
package_serverless:
	$(call cfn-package,serverless.yaml)

##################
# DEPLOY RESOURCES
##################
.PHONY: deploy_serverless
deploy_serverless: package_serverless
	$(call cfn-deploy-serverless,serverless.yaml)

###############
# Misc rules/vars
###############
cfn-package =  @echo "\n----- CFN package START -----\n" && \
    mkdir -p cloudformation/dist && \
	aws cloudformation package \
	--template-file cloudformation/${1} \
	--output-template-file cloudformation/dist/${1} \
	--s3-bucket $(ARTIFACTS_BUCKET) \
	--s3-prefix $(ARTIFACTS_PREFIX) && \
	echo "\n----- CFN package DONE -----\n"

cfn-deploy-serverless = @echo "\n----- Deploying API START -----\n" && \
	aws s3 cp cloudformation/swagger.yaml $(SWAGGER_PATH) && \
	aws cloudformation deploy \
	--tags Environment=$(ENVIRONMENT) \
				"UpdatedDate=$(NOW)" \
				"Repository=$(REPOS)" \
				"git-sha=$(REV)" \
				"git-branch"=$(shell git rev-parse --abbrev-ref HEAD) \
	--template-file cloudformation/dist/${1} \
	--stack-name $(SERVERLESS_STACK_NAME)\
	--capabilities CAPABILITY_NAMED_IAM \
	--region $(AWS_REGION) \
	--parameter-overrides \
	Service=$(SERVICE) \
	Swagger=$(SWAGGER_PATH) \
	Environment=$(ENVIRONMENT) && \
	echo "\n----- Deploying API functions DONE -----\n"

cfn-deploy = $(call cfn-package,${1}) && \
	aws cloudformation deploy \
	--template-file cloudformation/dist/${1}.yml \
	--stack-name $(SERVICE)-${1} \
	--capabilities CAPABILITY_NAMED_IAM \
	--region $(AWS_REGION) \
	--tags Environment=$(ENVIRONMENT) \
	--no-fail-on-empty-changeset \
	--parameter-overrides \
		Service=$(SERVICE) \
		Environment=$(ENVIRONMENT) \
		Region=${AWS_REGION}
clean:
	npm cache clean --force
	rm -rf node_modules
	for f in src/*; do \
		([ -d $$f ] && cd "$$f" && rm -rf node_modules) \
  done;

install:
	npm install
	for f in src/*; do \
		([ -d $$f ] && cd "$$f" && npm install) \
  done;

install_production:
	npm install --production
	for f in src/*; do \
		([ -d $$f ] && cd "$$f" && npm install --production) \
  done;

prune:
	npm prune --production
	for f in src/*; do \
		([ -d $$f ] && cd "$$f" && npm prune --production) \
  done;

ci: install prune

.PHONY: deploy
deploy: deploy_serverless
