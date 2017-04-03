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

get_message() {

  declare -r STATUS=$1
  declare -r DEPLOYMENT=$2
  declare -r DEPLOY_URL=$3

  if [ "$STATUS" == "succeeded" ]; then
    echo ":rocket: deployment of $DEPLOYMENT $STATUS ($DEPLOY_URL)"
  else
    echo ":warning: deployment of $DEPLOYMENT $STATUS"
  fi

}

github_commenter() {

  declare -r MSG="$1"
  declare -r PULL_REQUEST="$TRAVIS_PULL_REQUEST"
  declare -r REPO_SLUG="$TRAVIS_REPO_SLUG"

  fold_start "Post_To_Github"

  PAYLOAD="{\"body\": \"${MSG}\" }"

  GITHUB_RESPONSE=$(curl -s -o /dev/null -w '%{http_code}' -d "${PAYLOAD}" "https://api.github.com/repos/${REPO_SLUG}/issues/${PULL_REQUEST}/comments?access_token=${GITHUB_ACCESS_TOKEN}")

  if [ "${GITHUB_RESPONSE}" = "201" ]; then
    echo "Comment '${MSG}' added to pr ${PULL_REQUEST} on ${REPO_SLUG}"
  else
    echo "Failed to add comment to pr ${PULL_REQUEST} on ${REPO_SLUG} (response code: \"${GITHUB_RESPONSE}\")"
  fi

  fold_end "Post_To_Github"

}

slack_commenter() {

  declare -r MSG="$1"

  SLACK_RESPONSE=$(curl -s --data-urlencode "text=$MSG" "https://slack.com/api/chat.postMessage?token=${SLACK_TOKEN}&channel=${SLACK_CHANNEL_ID}")

  fold_start "Post_To_Slack"

  if [ "$(jq '.ok' <<< "${SLACK_RESPONSE}")" == "true" ]; then
    echo "Comment '${MSG}' posted to slack channel ${SLACK_CHANNEL_ID}"
  else
    echo "Failed to post comment '${MSG}' slack channel ${SLACK_CHANNEL_ID} (${SLACK_RESPONSE})"
  fi

  fold_end "Post_To_Slack"

}

deploy() {

  declare -r IMAGE_TAG=$1
  declare -r COMMENTER=$2
  declare REPO_NAME
  declare SANITISED_REPO_NAME

  fold_start "Generate_answers.txt"

  echo "Rancher values: server=${RANCHER_SERVER} catalog=${RANCHER_CATALOG_NAME} template=${RANCHER_TEMPLATE_NAME}"

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
  declare -r RANCHER_STACK_NAME="${REPO_NAME}-${IMAGE_TAG}"

  echo "${SANITISED_REPO_NAME}_DOCKER_IMAGE_TAG=${IMAGE_TAG}" >> answers.txt

  fold_end "Generate_answers.txt"

  echo -e "\nBuilding rancher stack ${RANCHER_STACK_NAME} in environment ${RANCHER_ENVIRONMENT}\n"

  fold_start "Rancher_Up"

  # REMOVE STACK IF PRESENT
  if rancher stack ls | grep "${RANCHER_STACK_NAME}"; then
    rancher rm --stop --type stack "${RANCHER_STACK_NAME}"
  fi

  if rancher --wait catalog install --answers answers.txt --name "${RANCHER_STACK_NAME}" "${RANCHER_CATALOG_NAME}"/"${RANCHER_TEMPLATE_NAME}"; then
    MSG="$(get_message "succeeded" "${RANCHER_STACK_NAME} in ${RANCHER_ENVIRONMENT}" "http://${RANCHER_STACK_NAME}.dev.c2s.nhschoices.net")"
    eval "$COMMENTER \"$MSG\""
  else
    MSG="$(get_message "failed" "${RANCHER_STACK_NAME} in ${RANCHER_ENVIRONMENT}")"
    eval "$COMMENTER \"$MSG\""
    exit 1
  fi

  fold_end "Rancher_Up"

}

if [ "$TRAVIS_PULL_REQUEST" != false ] ; then
  deploy "pr-${TRAVIS_PULL_REQUEST}" "github_commenter"
elif [ "$TRAVIS_BRANCH" == "master" ]; then
  deploy "latest" "slack_commenter"
fi
