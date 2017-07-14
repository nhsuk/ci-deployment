#!/bin/bash

# INSTALL RANCHER
bash ./common/install-rancher.sh


# EMULATE GITLAB_CI DEPLOY TO MASTER
GITLAB_CI=true \
CI_PROJECT_NAME=ci-test \
CI_ENVIRONMENT_NAME=dev \
CI_PROJECT_PATH=nhsuk-citest \
CI_COMMIT_REF_SLUG=master \
  bash ./common/deploy.sh

# EMULATE GITLAB_CI DEPLOY TO TAG
GITLAB_CI=true \
CI_PROJECT_NAME=ci-test \
CI_ENVIRONMENT_NAME=dev \
CI_PROJECT_PATH=nhsuk-citest \
CI_COMMIT_REF_SLUG=master \
CI_COMMIT_TAG=0.2.0 \
  bash ./common/deploy.sh

# EMULATE GITLAB_CI DEPLOY TO TAG
GITLAB_CI=true \
CI_PROJECT_NAME=ci-test \
CI_ENVIRONMENT_NAME=dev \
CI_PROJECT_PATH=nhsuk-citest \
CI_COMMIT_REF_SLUG=review-app \
  bash ./common/deploy.sh
