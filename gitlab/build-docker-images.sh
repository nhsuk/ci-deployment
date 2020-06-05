#!/bin/bash

bash ./scripts/ci-deployment/common/generate-answers.sh

IMAGE_TAG="$1"

# EXPORT ALL THE VARIABLES FROM THE GENERATED ANSWERS FILE
set -o allexport
# shellcheck source=/dev/null
source answers.txt
set +o allexport

# Delete answers.txt before building docker image to ensure secrets aren't leaked into the image
rm answers.txt

docker login -u "$DOCKER_USERNAME" -p "$DOCKER_PASSWORD"
docker build -t "nhsuk/${CI_PROJECT_NAME}:${IMAGE_TAG}" .
docker push "nhsuk/${CI_PROJECT_NAME}:${IMAGE_TAG}"
