#!/bin/bash

# INSTALL RANCHER
bash ./scripts/ci-deployment/common/install-rancher.sh
bash ./scripts/ci-deployment/common/generate-answers.sh


# EXPORT ALL THE VARIABLES FROM THE GENERATED ANSWERS FILE
set -o allexport
# shellcheck source=/dev/null
source answers.txt
set +o allexport

if [ "$TRAVIS" = "true" ]; then
  bash ./scripts/ci-deployment/travis/build-docker-images.sh
fi

bash ./scripts/ci-deployment/common/deploy.sh
