#!/usr/bin/env bash

# See here http://redsymbol.net/articles/unofficial-bash-strict-mode/ the rational for using u, e and o bash options

#Display error message for missing variables
set -u

#Exit with error code if any command fails
set -e

#prevents errors in a pipeline from being masked
set -o pipefail

declare -r NHSUK_GITHUB_URL="https://api.github.com/repos/nhsuk"

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

find_latest_rancher_template() {

  declare -r TEMPLATE_URL_BASE=$1
  declare TEMPLATE_VERSION; TEMPLATE_VERSION=0

  until [ "$(get_http_response "${TEMPLATE_URL_BASE}/${TEMPLATE_VERSION}/docker-compose.yml")" != "200" ]; do
    TEMPLATE_VERSION=$((TEMPLATE_VERSION + 1))
  done

  echo $((TEMPLATE_VERSION - 1))
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

get_http_response() {
  declare -r URL=$1
  #Check file exists
  declare RESPONSE; RESPONSE=$(curl -IsS -o /dev/null -w '%{http_code}' "${URL}")
  echo "$RESPONSE"
}

create_compose_file() {
  declare -r COMPOSE_TYPE=$1
  declare -r FILENAME="${COMPOSE_TYPE}-compose.yml"
  declare -r TEMPLATE_URL_BASE="https://raw.githubusercontent.com/nhsuk/nhsuk-rancher-templates/${RANCHER_TEMPLATE_BRANCH_NAME:-master}/templates/${RANCHER_TEMPLATE_NAME}"

  TEMPLATE_VERSION=$(find_latest_rancher_template "${TEMPLATE_URL_BASE}")
  declare -r TEMPLATE_URL="${TEMPLATE_URL_BASE}/${TEMPLATE_VERSION}/${COMPOSE_TYPE}-compose.yml"


  declare RESPONSE; RESPONSE=$(get_http_response "${TEMPLATE_URL}")

  if [ "${RESPONSE}" = "200" ]; then
    curl -Ss "${TEMPLATE_URL}"  -o "${FILENAME}"
  else
    echo "Failed to get ${TEMPLATE_URL} (response code: ${RESPONSE})" >&2
    exit 1
  fi

  echo -e "\n${FILENAME}\n"; cat "${FILENAME}"
}

check_repo_exists() {
  declare -r REPO=$1
  declare -r URL="${NHSUK_GITHUB_URL}/${REPO}"
  declare RESPONSE; RESPONSE=$(get_http_response "${URL}")

  if [ "${RESPONSE}" != "200" ]; then
    echo "Could not access GitHub repo '${REPO}'. Check it exists and is public. (url: ${URL}, response code: ${RESPONSE})." >&2
    exit 1
  fi
}

get_latest_release() {
  declare -r REPO=$1
  declare -r URL="${NHSUK_GITHUB_URL}/${REPO}"

  LATEST_RELEASE=$(curl -s "${URL}/releases/latest" | jq -r '.tag_name')

  if [ "${LATEST_RELEASE}" == "null" ]; then
    echo "GitHub repo '${REPO}' does not have a latest release. (url: ${URL})." >&2
    exit 1
  fi

  echo "$LATEST_RELEASE"
}

install_rancher() {
  declare -r RANCHER_CLI_VERSION='v0.6.0-rc2'
  mkdir tmp bin
  wget -qO- https://github.com/rancher/cli/releases/download/${RANCHER_CLI_VERSION}/rancher-linux-amd64-${RANCHER_CLI_VERSION}.tar.gz | tar xvz -C tmp
  mv tmp/rancher-${RANCHER_CLI_VERSION}/rancher bin/rancher
  chmod +x bin/rancher
  rm -r tmp/rancher-${RANCHER_CLI_VERSION}
  PATH=$PATH:./bin
}

if [ "$TRAVIS" == true ]; then

  if [ "$TRAVIS_PULL_REQUEST" != false ]; then

    if [ ! "$(command -v rancher)" ]; then
      install_rancher
    fi

    fold_start "Getting compose files"

    create_compose_file "docker"
    create_compose_file "rancher"

    fold_end "Getting compose files"

    eval "$(python -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout)' < rancher-compose.yml | jq --raw-output '.catalog.questions[] | select(.variable != "gp_finder_docker_image_tag" and .default != null) | @text "export \(.variable)=\(.default)"')"

    REPO_NAME=$(get_repo_name "${TRAVIS_REPO_SLUG}")
    SANITISED_REPO_NAME=$(sanitise_repo_name "${REPO_NAME}")

    eval "export ${SANITISED_REPO_NAME}_DOCKER_IMAGE_TAG=pr-${TRAVIS_PULL_REQUEST}"

    RANCHER_STACK_NAME="${REPO_NAME}-pr-${TRAVIS_PULL_REQUEST}"

    echo -e "\nBuilding rancher stack ${RANCHER_STACK_NAME} in environment ${RANCHER_ENVIRONMENT}\n"

    fold_start "Rancher up"
    if rancher -w up --force-upgrade --confirm-upgrade -d --stack "${RANCHER_STACK_NAME}"; then
      DEPLOY_URL="http://${RANCHER_STACK_NAME}.dev.c2s.nhschoices.net"
      MSG=":rocket: deployed to [${DEPLOY_URL}](${DEPLOY_URL})"
    else
      MSG=":warning: deployment of ${TRAVIS_PULL_REQUEST} for ${TRAVIS_REPO_SLUG} failed"
    fi
    fold_end "Rancher up"

    PAYLOAD="{\"body\": \"${MSG}\" }"

    GITHUB_RESPONSE=$(curl -s -o /dev/null -w '%{http_code}' -d "${PAYLOAD}" "https://api.github.com/repos/${TRAVIS_REPO_SLUG}/issues/${TRAVIS_PULL_REQUEST}/comments?access_token=${GITHUB_ACCESS_TOKEN}")

    if [ "${GITHUB_RESPONSE}" = "201" ]; then
      echo "Comment '${MSG}' added to pr ${TRAVIS_PULL_REQUEST} on ${TRAVIS_REPO_SLUG}"
    else
      echo "Failed to add comment to pr ${TRAVIS_PULL_REQUEST} on ${TRAVIS_REPO_SLUG} (response code: \"${GITHUB_RESPONSE}\")"
    fi

  fi

fi
