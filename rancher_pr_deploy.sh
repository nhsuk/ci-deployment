#!/usr/bin/env bash

# See here http://redsymbol.net/articles/unofficial-bash-strict-mode/ the rational for using u, e and o bash options

#Display error message for missing variables
set -u

#Exit with error code if any command fails
set -e

#prevents errors in a pipeline from being masked
set -o pipefail

declare -r RANCHER_SERVER="https://rancher.nhschoices.net"
declare -r RANCHER_CATALOG_NAME="NHSuk_Staging"
declare -r RANCHER_URL="${RANCHER_SERVER}/v2-beta/schemas"

fold_start() {
  if [[ -n $TRAVIS ]]; then
    printf "%s\n" "travis_fold:start:$*"
  fi
}

fold_end() {
  if [[ -n $TRAVIS ]]; then
    printf "%s\n" "travis_fold:end:$*"
  fi
}

sanitise_repo_name() {
  echo "$1" | tr '-' '_' | tr '[:lower:]' '[:upper:]'
}

get_repo_name() {
  declare -r REPO_SLUG=$1
  # need two args for the split but ORG is not needed
  # shellcheck disable=SC2034
  IFS=/ read -r ORG REPO <<< "${REPO_SLUG}"

  echo "${REPO}"
}

rancher() {
  declare -r RANCHER_CLI_VERSION='v0.6.0-rc2'

  docker run \
    --rm \
    -e RANCHER_URL="${RANCHER_URL}" \
    -e RANCHER_ENVIRONMENT="${RANCHER_ENVIRONMENT}" \
    -e RANCHER_ACCESS_KEY="${RANCHER_ACCESS_KEY}" \
    -e RANCHER_SECRET_KEY="${RANCHER_SECRET_KEY}" \
    -v "$(pwd)":/mnt \
    rancher/cli:${RANCHER_CLI_VERSION} \
    "$@"
}

post_comment_to_github() {

  declare -r MSG=$1
  declare -r PULL_REQUEST=$2
  declare -r REPO_SLUG=$3

  if [ "$TRAVIS_PULL_REQUEST" != false ] ; then

    fold_start "Post_To_Github"

    PAYLOAD="{\"body\": \"${MSG}\" }"

    GITHUB_RESPONSE=$(curl -s -o /dev/null -w '%{http_code}' -d "${PAYLOAD}" "https://api.github.com/repos/${REPO_SLUG}/issues/${PULL_REQUEST}/comments?access_token=${GITHUB_ACCESS_TOKEN}")

    if [ "${GITHUB_RESPONSE}" = "201" ]; then
      echo "Comment '${MSG}' added to pr ${PULL_REQUEST} on ${REPO_SLUG}"
    else
      echo "Failed to add comment to pr ${PULL_REQUEST} on ${REPO_SLUG} (response code: \"${GITHUB_RESPONSE}\")"
    fi

    fold_end "Post_To_Github"

  fi
}

deploy() {

  fold_start "Generate_answers.txt"

  RANCHER_CATALOG_ID=$( curl -su "${RANCHER_ACCESS_KEY}:${RANCHER_SECRET_KEY}" "${RANCHER_SERVER}/v1-catalog/templates/${RANCHER_CATALOG_NAME}:${RANCHER_TEMPLATE_NAME}" | jq --raw-output '.defaultTemplateVersionId' )

  if [ -z "${RANCHER_CATALOG_ID}" ]; then
    echo "Rancher Catalog Id (aka defaultTemplateVersionId) from ${RANCHER_SERVER}/v1-catalog/templates/${RANCHER_CATALOG_NAME}:${RANCHER_TEMPLATE_NAME} is unknown."
    echo "Make sure it is defined in config.yml and that it matches the latest one is used in the template directories."
    exit 1
  fi

  curl -su "${RANCHER_ACCESS_KEY}:${RANCHER_SECRET_KEY}" "${RANCHER_SERVER}/v1-catalog/templates/${RANCHER_CATALOG_ID}" | \
    jq --raw-output '.questions[] | @text "\(.variable)=\(.default)"' > answers.txt

  REPO_NAME=$(get_repo_name "${TRAVIS_REPO_SLUG}")
  SANITISED_REPO_NAME=$(sanitise_repo_name "${REPO_NAME}")

  echo "${SANITISED_REPO_NAME}_DOCKER_IMAGE_TAG=${IMAGE_TAG}" >> answers.txt

  fold_end "Generate_answers.txt"

  echo -e "\nBuilding rancher stack ${RANCHER_STACK_NAME} in environment ${RANCHER_ENVIRONMENT}\n"

  fold_start "Rancher_Up"

  # REMOVE STACK IF PRESENT
  if rancher stack ls | grep "${RANCHER_STACK_NAME}"; then
    rancher rm --stop --type stack "${RANCHER_STACK_NAME}"
  fi

  if rancher catalog install --answers answers.txt --name "${RANCHER_STACK_NAME}" "${RANCHER_CATALOG_NAME}"/"${RANCHER_TEMPLATE_NAME}"; then
    DEPLOY_URL="http://${RANCHER_STACK_NAME}.dev.c2s.nhschoices.net"
    MSG=":rocket: deployed to [${DEPLOY_URL}](${DEPLOY_URL})"
    post_comment_to_github "$MSG" "$TRAVIS_PULL_REQUEST" "$TRAVIS_REPO_SLUG"
  else
    MSG=":warning: deployment of ${TRAVIS_PULL_REQUEST} for ${TRAVIS_REPO_SLUG} to rancher stack ${RANCHER_STACK_NAME} failed"
    post_comment_to_github "$MSG" "$TRAVIS_PULL_REQUEST" "$TRAVIS_REPO_SLUG"
    exit 1
  fi

  fold_end "Rancher_Up"
}


REPO_NAME=$(get_repo_name "${TRAVIS_REPO_SLUG}")

if [ "$TRAVIS" == true ] && [ "$TRAVIS_PULL_REQUEST" != false ] ; then
  RANCHER_STACK_NAME="${REPO_NAME}-pr-${TRAVIS_PULL_REQUEST}"
  IMAGE_TAG="pr-${TRAVIS_PULL_REQUEST}"
  deploy
elif [ "$TRAVIS_BRANCH" == "master" ]; then
  RANCHER_STACK_NAME="${REPO_NAME}-latest"
  IMAGE_TAG="latest"
  deploy
fi
