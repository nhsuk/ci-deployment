#!/bin/bash

# SET SOME SANE DEFAULTS
{
  echo "RANCHER_STACK_NAME=${CI_PROJECT_NAME}"
  echo "DEPLOY_URL='${CI_PROJECT_NAME}.${CI_ENVIRONMENT_NAME}.beta.nhschoices.net'"
  echo "RANCHER_DESCRIPTION='${CI_REPOSITORY_URL}'"
} >> answers.txt

# TAG BUILDS
if [ -n "${CI_COMMIT_TAG}" ]; then
  echo "DOCKER_IMAGE_TAG=${CI_COMMIT_TAG}" >> answers.txt
# INTEGRATION BUILD
elif [ "$CI_COMMIT_REF_SLUG" = "master" ]; then
  echo "DOCKER_IMAGE_TAG=latest" >> answers.txt
else
  # IT'S A BRANCH
  echo "DEPLOY_URL='${CI_PROJECT_NAME}-${CI_COMMIT_REF_SLUG}.dev.beta.nhschoices.net'" >> answers.txt
  echo "RANCHER_STACK_NAME='${CI_PROJECT_NAME}-${CI_COMMIT_REF_SLUG}'" >> answers.txt
  echo "DOCKER_IMAGE_TAG=${CI_COMMIT_REF_SLUG}" >> answers.txt
  echo "RANCHER_DESCRIPTION='(${CI_COMMIT_REF_SLUG}) (${CI_REPOSITORY_URL})'" >> answers.txt
fi
