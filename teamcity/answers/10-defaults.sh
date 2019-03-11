#!/bin/bash

# SET SOME SANE DEFAULTS
{
  echo "RANCHER_STACK_NAME=${TEAMCITY_PROJECT_NAME}"
  echo "PROJECT_NAME=${TEAMCITY_PROJECT_NAME}"
  if [ "$CI_ENVIRONMENT_NAME" = "dev" ]; then
    echo "DEPLOY_URL='${CI_PROJECT_NAME}.nhswebsite-integration.nhs.uk'"
  elif [ "$CI_ENVIRONMENT_NAME" = "integration" ]; then
    echo "DEPLOY_URL='${CI_PROJECT_NAME}.nhswebsite-integration.nhs.uk'"
  else [ "$CI_ENVIRONMENT_NAME" = "staging" ]; then
    echo "DEPLOY_URL='${CI_PROJECT_NAME}.nhswebsite-staging.nhs.uk'"
  fi
  echo "RANCHER_DESCRIPTION='github/nhsuk/${TEAMCITY_PROJECT_NAME}'"
  echo "DEPLOY_BUILD=true"
} >> answers.txt

# TEAMCITY ONLY USED FOR PROMOTING TAGS TO STAGING/PRODUCTION
echo "DOCKER_IMAGE_TAG=${BUILD_TAG}" >> answers.txt
