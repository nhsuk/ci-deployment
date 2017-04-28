#!/bin/bash

get_repo_name() {
  echo "$TRAVIS_REPO_SLUG" | cut -d "/" -f 2-
}

REPO_STUB=$(get_repo_name)

echo "TODO: Generate Answers file properly"


# SET SOME SANE DEFAULTS
echo "" > answers.txt
{
  echo "RANCHER_SERVER=rancher.nhschoices.net"
  echo "RANCHER_URL=https://rancher.nhschoices.net/v2-beta/schemas"
  echo "RANCHER_ENVIRONMENT=nhsuk-dev"
  echo "RANCHER_STACK_NAME=${REPO_STUB}"
  echo "TRAEFIK_DOMAIN=dev.beta.nhschoices.net"
  echo "DEPLOY_URL='${REPO_STUB}.dev.beta.nhschoices.net'"
  echo "REPO_NAME=$(get_repo_name)"
} >> answers.txt

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
  echo "DOCKER_IMAGE_TAG=latest" | tee --append answers.txt

  # LOAD STAGING_SECRETS IF AVAILABLE
  if [ -n "$STAGING_SECRETS" ]; then
    for SECRET in $STAGING_SECRETS; do
      echo "$SECRET" >> answers.txt
    done
  fi

fi
