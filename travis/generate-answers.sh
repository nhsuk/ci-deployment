#!/bin/bash

REPO_STUB=$(sh ./scripts/ci-deployment/travis/get-repo-name.sh)

echo "TODO: Generate Answers file properly"

# CHECK RANCER_SERVER ENV EXISTS
if [ -z "$RANCHER_SERVER" ]; then
  echo "RANCHER_SERVER not set, setting to the default"
fi

# IF RANCHER_ENVIRONMENT NOT SET, SET TO A DEFAULT
if [ -z "$RANCHER_ENVIRONMENT" ]; then
  echo "RANCHER_ENVIRONMENT not set, setting to the default"
fi

# IF TRAEFIK_DOMAIN NOT SET, SET TO A DEFAULT
if [ -z "$TRAEFIK_DOMAIN" ]; then
  echo "TRAEFIK_DOMAIN not set, setting to the default"
fi

# SET SOME SANE DEFAULTS
{
  echo "RANCHER_URL=https://${RANCHER_SERVER-rancher.nhschoices.net}/v2-beta/schemas"
  echo "RANCHER_ENVIRONMENT=${RANCHER_ENVIRONMENT-nhsuk-dev}"
  echo "RANCHER_STACK_NAME=${REPO_STUB}"
  echo "TRAEFIK_DOMAIN=${TRAEFIK_DOMAIN-dev.beta.nhschoices.net}"
  echo "DEPLOY_URL='${REPO_STUB}.${TRAEFIK_DOMAIN-dev.beta.nhschoices.net}'"
  echo "REPO_NAME=$REPO_STUB"
} > answers.txt

# IF PR, DEPLOY TO DEV ENV
if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
  {
    echo "DOCKER_IMAGE_TAG=pr-${TRAVIS_PULL_REQUEST}"
    echo "RANCHER_STACK_NAME='${REPO_STUB}-pr-${TRAVIS_PULL_REQUEST}'"
    echo "DEPLOY_URL='${REPO_STUB}-pr-${TRAVIS_PULL_REQUEST}.dev.beta.nhschoices.net'"
  } >> answers.txt

# PRINT ANSWERS FILE BEFORE ADDING SECRETS
cat answers.txt

# IF MASTER, DEPLOY TO DEV ENV
elif [ "$TRAVIS_BRANCH" = "master" ]; then
  echo "DOCKER_IMAGE_TAG=latest" | tee -a answers.txt

  # LOAD STAGING_SECRETS IF AVAILABLE
  if [ -n "$STAGING_SECRETS" ]; then
    for SECRET in $STAGING_SECRETS; do
      echo "$SECRET" >> answers.txt
    done
  fi

fi
