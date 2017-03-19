#!/usr/bin/env bash

# See here http://redsymbol.net/articles/unofficial-bash-strict-mode/ the rational for using u, e and o bash options

#Display error message for missing variables
set -u

#Exit with error code if any command fails
set -e

#prevents errors in a pipeline from being masked
set -o pipefail

declare -r RANCHER_SERVER="https://rancher.nhschoices.net"
declare -r NHSUK_GITHUB_URL="https://api.github.com/repos/nhsuk"
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
    $@
}

if [ "$TRAVIS" == true ] && [ "$TRAVIS_PULL_REQUEST" != false ] ; then

  fold_start "Generate_answers.txt"
  # POPULATES ANSWERS FILE WITH THE DEFAULTS FROM THE RANCHER-COMPOSE FILE
  RANCHER_CATALOG_ID=$( curl -su "${RANCHER_ACCESS_KEY}:${RANCHER_SECRET_KEY}" "${RANCHER_SERVER}/v1-catalog/templates/${RANCHER_CATALOG_NAME}:${RANCHER_TEMPLATE_NAME}" | jq --raw-output '.defaultTemplateVersionId' )
  curl -su "${RANCHER_ACCESS_KEY}:${RANCHER_SECRET_KEY}" "${RANCHER_SERVER}/v1-catalog/templates/${RANCHER_CATALOG_ID}" | \
  jq --raw-output '.files["rancher-compose.yml"]' | \
    python -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout)' | \
    jq --raw-output '.catalog.questions[] | @text "\(.variable)=\(.default)"' > answers.txt

  REPO_NAME=$(get_repo_name "${TRAVIS_REPO_SLUG}")
  SANITISED_REPO_NAME=$(sanitise_repo_name "${REPO_NAME}")

  echo "${SANITISED_REPO_NAME}_DOCKER_IMAGE_TAG=pr-${TRAVIS_PULL_REQUEST}" >> answers.txt

  fold_end "Generate_answers.txt"

  RANCHER_STACK_NAME="${REPO_NAME}-pr-${TRAVIS_PULL_REQUEST}"

  echo -e "\nBuilding rancher stack ${RANCHER_STACK_NAME} in environment ${RANCHER_ENVIRONMENT}\n"

  fold_start "Rancher_Up"

  # REMOVE STACK IF PRESENT
  if rancher stack ls | grep "${RANCHER_STACK_NAME}"; then
    rancher rm --stop --type stack "${RANCHER_STACK_NAME}"
  fi

  if rancher catalog install --answers answers.txt --name "${RANCHER_STACK_NAME}" "${RANCHER_CATALOG_NAME}"/"${RANCHER_TEMPLATE_NAME}"; then
    DEPLOY_URL="http://${RANCHER_STACK_NAME}.dev.c2s.nhschoices.net"
    MSG=":rocket: deployed to [${DEPLOY_URL}](${DEPLOY_URL})"
  else
    MSG=":warning: deployment of ${TRAVIS_PULL_REQUEST} for ${TRAVIS_REPO_SLUG} failed"
  fi
  fold_end "Rancher_Up"


  fold_start "Post_To_Github"
  PAYLOAD="{\"body\": \"${MSG}\" }"

  GITHUB_RESPONSE=$(curl -s -o /dev/null -w '%{http_code}' -d "${PAYLOAD}" "https://api.github.com/repos/${TRAVIS_REPO_SLUG}/issues/${TRAVIS_PULL_REQUEST}/comments?access_token=${GITHUB_ACCESS_TOKEN}")

  if [ "${GITHUB_RESPONSE}" = "201" ]; then
    echo "Comment '${MSG}' added to pr ${TRAVIS_PULL_REQUEST} on ${TRAVIS_REPO_SLUG}"
  else
    echo "Failed to add comment to pr ${TRAVIS_PULL_REQUEST} on ${TRAVIS_REPO_SLUG} (response code: \"${GITHUB_RESPONSE}\")"
  fi
  fold_end "Post_To_Github"

fi
