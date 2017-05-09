#!/bin/bash

# INSTALL RANCHER
bash ./scripts/ci-deployment/common/install-rancher.sh

if [ "$GITLAB_CI" = "true" ]; then
  bash ./scripts/ci-deployment/gitlab/generate-answers.sh
  bash ./scripts/ci-deployment/gitlab/deploy.sh
fi

if [ "$TRAVIS" = "true" ]; then
  bash ./scripts/ci-deployment/travis/build-docker-images.sh
  bash ./scripts/ci-deployment/travis/generate-answers.sh
  bash ./scripts/ci-deployment/travis/deploy.sh
fi
