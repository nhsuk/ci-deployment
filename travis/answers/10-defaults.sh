#!/bin/bash

REPO_STUB=$(sh ./scripts/ci-deployment/travis/get-repo-name.sh)

# SET SOME SANE DEFAULTS
{
  echo "RANCHER_STACK_NAME=${REPO_STUB}"
  echo "DEPLOY_URL='${REPO_STUB}.${TRAEFIK_DOMAIN-dev.beta.nhschoices.net}'"
  echo "REPO_NAME=$REPO_STUB"
  echo "PROJECT_NAME=$REPO_STUB"
  echo "RANCHER_DESCRIPTION=github/${TRAVIS_REPO_SLUG}"
  echo "DEPLOY_BUILD=false"
} >> answers.txt

# IF PR, DEPLOY TO DEV ENV
if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
  {
    echo "NOTIFICATION_METHOD=github"
    echo "DEPLOY_BUILD=true"
    echo "DOCKER_IMAGE_TAG=pr-${TRAVIS_PULL_REQUEST}"
    echo "RANCHER_STACK_NAME='${REPO_STUB}-pr-${TRAVIS_PULL_REQUEST}'"
    echo "DEPLOY_URL='${REPO_STUB}-pr-${TRAVIS_PULL_REQUEST}.dev.beta.nhschoices.net'"
    echo "RANCHER_DESCRIPTION='PR-${TRAVIS_PULL_REQUEST} (${TRAVIS_PULL_REQUEST_BRANCH}) github/${TRAVIS_REPO_SLUG}'"
  } >> answers.txt

# IF MASTER, DEPLOY TO DEV ENV
elif [ "$TRAVIS_BRANCH" = "master" ]; then
  echo "DEPLOY_BUILD=true"
  echo "DOCKER_IMAGE_TAG=latest" >> answers.txt
fi
