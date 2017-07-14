#!/bin/bash

# INSTALL RANCHER
bash ./common/install-rancher.sh

bash ./common/generate-answers.sh

# EXPORT ALL THE VARIABLES FROM THE GENERATED ANSWERS FILE
set -o allexport
# shellcheck source=/dev/null
source answers.txt
set +o allexport

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
