#!/bin/bash

# BLANK ANSWERS FILE IF IT ALREADY EXISTED
echo "" > answers.txt

# LOAD ALL COMMON ANSWER FILES, IF DIRECTORY EXISTS
if [ -d "./scripts/ci-deployment/common/answers" ]; then
  for f in ./scripts/ci-deployment/common/answers/*; do
    echo "Loading answers from $f"
    # shellcheck source=/dev/null
    . "$f"
  done
fi

# SET CI_TOOL VARIABLE
if [ "$GITLAB_CI" = "true" ]; then
  CI_TOOL="gitlab"
elif [ "$TRAVIS" = "true" ]; then
  CI_TOOL="travis"
elif [ -n "$TEAMCITY_VERSION" ]; then
  CI_TOOL="teamcity"
else
  CI_TOOL="manual"
fi
export CI_TOOL
echo "CI_TOOL=$CI_TOOL" >> answers.txt

# LOAD CI TOOL SPECIFIC ANSWER FILES, IF DIRECTORY EXISTS
if [ -d "./scripts/ci-deployment/${CI_TOOL}/answers" ]; then
  for f in ./scripts/ci-deployment/${CI_TOOL}/answers/*; do
    echo "Loading answers from $f"
    # shellcheck source=/dev/null
    . "$f"
  done
fi

# REPO SPECIFIC ANSWERS, IF DIRECTORY EXISTS
if [ -d "./scripts/answers.d" ]; then
  for f in ./scripts/answers.d/*; do
    echo "Loading answers from $f"
    # shellcheck source=/dev/null
    . "$f"
  done
fi

# Always skip the deployment if flag set
if [ "$SKIP_DEPLOY" = "true" ]; then
  echo "DEPLOY_BUILD=false" >> answers.txt
fi

# ENSURE answers.txt isn't in the Dockerfile!
echo "answers.txt" >> .dockerignore
