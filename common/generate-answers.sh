#!/bin/bash

# LOAD ALL COMMON ANSWER FILES, IF DIRECTORY EXISTS
if [ -d "./scripts/ci-deployment/common/answers" ]; then
  for f in ./scripts/ci-deployment/common/answers/*; do
    echo "Loading answers from $f"
    # shellcheck source=/dev/null
    . "$f"
  done
fi

# LOAD ALL GITLAB ANSWER FILES, IF DIRECTORY EXISTS
if [ "$GITLAB_CI" = "true" ] && [ -d "./scripts/ci-deployment/gitlab/answers" ]; then
  for f in ./scripts/ci-deployment/gitlab/answers/*; do
    echo "Loading answers from $f"
    # shellcheck source=/dev/null
    . "$f"
  done
fi

# LOAD ALL TEAMCITY ANSWER FILES, IF DIRECTORY EXISTS
if [ -n "$TEAMCITY_VERSION" ] && [ -d "./scripts/ci-deployment/teamcity/answers" ]; then
  for f in ./scripts/ci-deployment/teamcity/answers/*; do
    echo "Loading answers from $f"
    # shellcheck source=/dev/null
    . "$f"
  done
fi

# LOAD ALL TRAVIS ANSWER FILES, IF DIRECTORY EXISTS
if [ "$TRAVIS" = "true" ] && [ -d "./scripts/ci-deployment/travis/answers" ]; then
  for f in ./scripts/ci-deployment/travis/answers/*; do
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

# ENSURE answers.txt isn't in the Dockerfile!
echo "answers.txt" >> .dockerignore
