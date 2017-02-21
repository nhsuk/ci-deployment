#!/usr/bin/env bash

declare -a DEPENDANT_SERVICES=($@)

sanitise_repo_name() {
  echo "$1" | tr '-' '_'
}

get_repo_name() {
  REPO_SLUG=$1
  # need two args for the split but ORG is not needed
  # shellcheck disable=SC2034 
  IFS=/ read -r ORG REPO <<< "${REPO_SLUG}"

  echo "${REPO}"
}

install_rancher() {
  RANCHER_CLI_VERSION='v0.4.1'
  mkdir tmp bin
  wget -qO- https://github.com/rancher/cli/releases/download/${RANCHER_CLI_VERSION}/rancher-linux-amd64-${RANCHER_CLI_VERSION}.tar.gz | tar xvz -C tmp
  mv tmp/rancher-${RANCHER_CLI_VERSION}/rancher bin/rancher
  chmod +x bin/rancher
  rm -r tmp/rancher-${RANCHER_CLI_VERSION}
  PATH=$PATH:./bin
}

if [[ -n "$TRAVIS" ]]; then

  echo "Travis detected"

  # IF PULL REQUEST
  if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then

    if [ ! "$(command -v rancher)" ]
    then 
      install_rancher
    fi

    curl -s "https://raw.githubusercontent.com/nhsuk/nhsuk-rancher-templates/feature/changes-for-ci-script/templates/${RANCHER_TEMPLATE_NAME}/0/docker-compose.yml"  -o docker-compose.yml
    curl -s "https://raw.githubusercontent.com/nhsuk/nhsuk-rancher-templates/feature/changes-for-ci-script/templates/${RANCHER_TEMPLATE_NAME}/0/rancher-compose.yml" -o rancher-compose.yml

    REPO_NAME=$(get_repo_name "${TRAVIS_REPO_SLUG}")
    SANITISED_REPO_NAME=$(sanitise_repo_name "${REPO_NAME}")

    cat <<EOT  > answers.txt
traefik_domain=dev.c2s.nhschoices.net
${SANITISED_REPO_NAME}_docker_image_tag=pr-${TRAVIS_PULL_REQUEST}
splunk_hec_endpoint=https://splunk-collector.cloudapp.net:8088
splunk_hec_token=${SPLUNK_HEC_TOKEN}
hotjar_id=265857
google_id=UA-67365892-5
webtrends_id=dcs222rfg0jh2hpdaqwc2gmki_9r4q
EOT
 
    if [ ${#DEPENDANT_SERVICES[@]} -ne 0 ]
    then
      for DEPENDANT_SERVICE in ${DEPENDANT_SERVICES[*]}; do
        LATEST_RELEASE=$(curl -s "https://api.github.com/repos/nhsuk/${DEPENDANT_SERVICE}/releases/latest" | jq -r '.tag_name')
        echo "$(sanitise_repo_name "$DEPENDANT_SERVICE")_docker_image_tag=${LATEST_RELEASE:-latest}" >> answers.txt
      done
    fi

    RANCHER_STACK_NAME="${REPO_NAME}-pr-${TRAVIS_PULL_REQUEST}"
    rancher -w up --pull --upgrade -d --stack "${RANCHER_STACK_NAME}" --env-file answers.txt

    if [ "$(rancher -w up --pull --upgrade -d --stack "${RANCHER_STACK_NAME}" --env-file answers.txt)" ]
    then
      DEPLOY_URL="http://${RANCHER_STACK_NAME}.dev.c2s.nhschoices.net"
      MSG=":rocket: deployed to [${DEPLOY_URL}](${DEPLOY_URL})"
    else
      MSG=":warning: deployment of ${TRAVIS_PULL_REQUEST} for ${TRAVIS_REPO_SLUG} failed"
    fi

    PAYLOAD="{\"body\": \"${MSG}\" }"

    GITHUB_RESPONSE=$(curl -s -d "${PAYLOAD}" "https://api.github.com/repos/${TRAVIS_REPO_SLUG}/issues/${TRAVIS_PULL_REQUEST}/comments?access_token=${GITHUB_ACCESS_TOKEN}" | jq -r '.body')

    echo "Comment added to pr ${TRAVIS_PULL_REQUEST} on ${TRAVIS_REPO_SLUG}: \"${GITHUB_RESPONSE}\""

  fi

fi
