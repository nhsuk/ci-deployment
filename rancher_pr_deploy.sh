#!/usr/bin/env bash

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

    install_rancher

    curl -s "https://raw.githubusercontent.com/nhsuk/nhsuk-rancher-templates/master/templates/${RANCHER_TEMPLATE_NAME}/0/docker-compose.yml"  -o docker-compose.yml
    curl -s "https://raw.githubusercontent.com/nhsuk/nhsuk-rancher-templates/master/templates/${RANCHER_TEMPLATE_NAME}/0/rancher-compose.yml" -o rancher-compose.yml

    touch answers.txt
    echo -n "" > answers.txt

    {
      echo "traefik_domain=dev.c2s.nhschoices.net"
      echo "profiles_docker_image_tag=pr-${TRAVIS_PULL_REQUEST}"
      echo "profiles_db_docker_image_tag=latest"
      echo "splunk_hec_endpoint=https://splunk-collector.cloudapp.net:8088"
      echo "splunk_hec_token=${SPLUNK_HEC_TOKEN}"
      echo "hotjar_id=265857"
      echo "google_id=UA-67365892-5"
      echo "webtrends_id=dcs222rfg0jh2hpdaqwc2gmki_9r4q"
    } >> answers.txt

    RANCHER_STACK_NAME="profiles-pr-${TRAVIS_PULL_REQUEST}"

    rancher -w up --pull --upgrade -d --stack "${RANCHER_STACK_NAME}" --env-file answers.txt

    DEPLOY_URL="http://${RANCHER_STACK_NAME}.dev.c2s.nhschoices.net"
    MSG=":rocket: deployed to [${DEPLOY_URL}](${DEPLOY_URL})"

    PAYLOAD="{\"body\": \"${MSG}\" }"

    curl -s -d "${PAYLOAD}" "https://api.github.com/repos/${TRAVIS_REPO_SLUG}/issues/${TRAVIS_PULL_REQUEST}/comments?access_token=${GITHUB_ACCESS_TOKEN}"

  fi

fi
