#!/bin/bash

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
echo "" > answers.txt
{
  echo "RANCHER_URL=https://${RANCHER_SERVER-rancher.nhschoices.net}/v2-beta/schemas"
  echo "RANCHER_ENVIRONMENT=${RANCHER_ENVIRONMENT-nhsuk-dev}"
  echo "RANCHER_STACK_NAME=${CI_PROJECT_NAME}"
  echo "TRAEFIK_DOMAIN=${CI_ENVIRONMENT_SLUG}.beta.nhschoices.net"
  echo "DEPLOY_URL='${CI_PROJECT_NAME}.${CI_ENVIRONMENT_NAME}.beta.nhschoices.net'"
} >> answers.txt

if [ -n "${CI_COMMIT_TAG}" ]; then
echo "DOCKER_IMAGE_TAG=${CI_COMMIT_TAG}" >> answers.txt
elif [ "$CI_COMMIT_REF_SLUG" = "master" ]; then
  echo "DOCKER_IMAGE_TAG=latest" >> answers.txt
else
  # IT'S A BRANCH
  echo "TRAEFIK_DOMAIN=dev.beta.nhschoices.net" >> answers.txt
  echo "DEPLOY_URL='${CI_PROJECT_NAME}-${CI_COMMIT_REF_SLUG}.dev.beta.nhschoices.net'" >> answers.txt
  echo "RANCHER_STACK_NAME='${CI_PROJECT_NAME}-${CI_COMMIT_REF_SLUG}'" >> answers.txt
  echo "DOCKER_IMAGE_TAG=${CI_COMMIT_REF_SLUG}" >> answers.txt
fi

# PRINT ANSWERS FILE BEFORE ADDING SECRETS
cat answers.txt

# LOAD STAGING_SECRETS IF AVAILABLE
if [ -n "$STAGING_SECRETS" ]; then
  for SECRET in $STAGING_SECRETS; do
    echo "$SECRET" >> answers.txt
  done
fi
