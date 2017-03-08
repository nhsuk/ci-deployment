#!/usr/bin/env bash

# See here http://redsymbol.net/articles/unofficial-bash-strict-mode/ the rational for using u, e and o bash options

#Display error message for missing variables
set -u

#Exit with error code if any command fails
set -e

#prevents errors in a pipeline from being masked
set -o pipefail

get_repo_name() {
  declare -r REPO_SLUG=$1
  # need two args for the split but ORG is not needed
  # shellcheck disable=SC2034
  IFS=/ read -r ORG REPO <<< "${REPO_SLUG}"

  echo "${REPO}"
}

if [ "$TRAVIS" == true ]; then

  if [ "$TRAVIS_PULL_REQUEST" != false ]; then

    REPO_NAME=$(get_repo_name "${TRAVIS_REPO_SLUG}")
    RANCHER_STACK_NAME="${REPO_NAME}-pr-${TRAVIS_PULL_REQUEST}"
    RANCHER_CATALOG_NAME="NHSuk (Staging)/${RANCHER_TEMPLATE_NAME}"

    # The echo accepts the default answers in an interactive script.
    if echo | rancher --env c2s-dev catalog install --name "${RANCHER_STACK_NAME}" "${RANCHER_CATALOG_NAME}"; then
      DEPLOY_URL="http://${RANCHER_STACK_NAME}.dev.c2s.nhschoices.net"
      MSG=":rocket: deployed to [${DEPLOY_URL}](${DEPLOY_URL})"
    else
      MSG=":warning: deployment of ${TRAVIS_PULL_REQUEST} for ${TRAVIS_REPO_SLUG} failed"
    fi

    PAYLOAD="{\"body\": \"${MSG}\" }"

    GITHUB_RESPONSE=$(curl -s -o /dev/null -w '%{http_code}' -d "${PAYLOAD}" "https://api.github.com/repos/${TRAVIS_REPO_SLUG}/issues/${TRAVIS_PULL_REQUEST}/comments?access_token=${GITHUB_ACCESS_TOKEN}")

    if [ "${GITHUB_RESPONSE}" = "201" ]; then
      echo "Comment '${MSG}' added to pr ${TRAVIS_PULL_REQUEST} on ${TRAVIS_REPO_SLUG}"
    else
      echo "Failed to add comment to pr ${TRAVIS_PULL_REQUEST} on ${TRAVIS_REPO_SLUG} (response code: \"${GITHUB_RESPONSE}\")"
    fi

  fi

fi
