#!/bin/bash

PUSH_TO_DOCKER=true
REPO_SLUG=$(sh ./scripts/ci-deployment/travis/get-repo-name.sh)
DOCKER_REPO="nhsuk/${REPO_SLUG}"
TAGS=""

info() {
  printf "%s\n" "$@"
}

fatal() {
  printf "**********\n"
  printf "%s\n" "$@"
  printf "**********\n"
  exit 1
}

fold_start() {
  if [ -n $TRAVIS ]; then
    printf "%s\n" "travis_fold:start:$*"
  fi
}

fold_end() {
  if [ -n $TRAVIS ]; then
    printf "%s\n" "travis_fold:end:$*"
  fi
}


# CREATE ARRAY OF DOCKER TAGS WE'RE GOING TO APPLY TO THE IMAGE

# IF PULL REQUEST BUILD, CREATE TAG FOR PR
if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then

  echo "Pull Request build detected, adding pr-${TRAVIS_PULL_REQUEST} to the docker tags"
  TAGS="$TAGS pr-${TRAVIS_PULL_REQUEST}"

elif [ -n "$TRAVIS" ]; then

  echo "Travis detected"

  # IF MASTER BRANCH ALWAYS SET THE LATEST TAG
  if [ "$TRAVIS_BRANCH" = "master" ]; then
    TAGS="$TAGS latest master"
  fi

  # ADD TAG BRANCH
  if [ -n "$TRAVIS_TAG" ]; then
    echo "Tag detected, adding ${TRAVIS_TAG} to the docker tags"
    TAGS="$TAGS $TRAVIS_TAG"
  fi

fi

if [ "$TAGS" != "" ]; then

  echo "Building Docker tags: $TAGS"

  fold_start "Building_Docker_Images"

  # LOGIN TO DOCKER HUB
  fold_start "Login_to_Docker_hub"
  if [ -z "$DOCKER_USERNAME" ]; then
    echo "DOCKER_USERNAME not set"
    exit 1
  fi
  if [ -z "$DOCKER_PASSWORD" ]; then
    echo "DOCKER_PASSWORD not set"
    exit 1
  fi
  docker login -u="$DOCKER_USERNAME" -p="$DOCKER_PASSWORD"
  fold_end "Login_to_Docker_hub"


  fold_start "Building_Default_Image"
  info "Building default image"

  if docker build -t "${REPO_SLUG}" .; then
    fatal "Build failed!"
  else
    info "Build succeeded."
  fi
  fold_end "Building_Default_Image"

  if [ "$PUSH_TO_DOCKER" = true ]; then
    fold_start "Tagging_and_pushing_images"

    for TAG in $TAGS; do
      fold_start "Pushing_'$TAG'"
      docker tag "$REPO_SLUG" "${DOCKER_REPO}:${TAG}"
      docker push "${DOCKER_REPO}:${TAG}"
      fold_end "Pushing_'$TAG'"
    done

    fold_end "Tagging_and_pushing_images"

  fi

  info "All builds successful!"

fi

exit 0
