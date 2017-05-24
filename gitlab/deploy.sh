#!/bin/bash

# See here http://redsymbol.net/articles/unofficial-bash-strict-mode/ the rational for using u, e and o bash options

set -u          #Display error message for missing variables
set -e          #Exit with error code if any command fails
set -o pipefail #prevents errors in a pipeline from being masked

check_rancher_vars() {

  RANCHER_ENVS="RANCHER_URL RANCHER_ENVIRONMENT RANCHER_ACCESS_KEY RANCHER_SECRET_KEY"

  for i in $RANCHER_ENVS; do
    VALUE=$(eval "echo \$$i")
    if [ ! -n "$VALUE" ]; then
      echo "RANCHER ENV VARIABLE $i NOT SET!"
      exit 1
    fi
  done

}

deploy() {

  check_rancher_vars

  echo "Building rancher stack $RANCHER_STACK_NAME in environment $RANCHER_ENVIRONMENT"

  pushd rancher-config/
  # ACTUALLY DEPLOY NOW
  ../rancher \
    --wait \
      up  -p \
          -d \
          --upgrade \
          --force-upgrade \
          --confirm-upgrade \
          --stack "${RANCHER_STACK_NAME}"
  popd

  if [ $? -eq 0 ]; then
    MSG=":rocket: deployment of $CI_PROJECT_NAME succeeded (http://$DEPLOY_URL)"
  else
    MSG=":warning: deployment of $CI_PROJECT_NAME failed"
  fi

  bash ./scripts/ci-deployment/common/post-comment-to-slack.sh "$MSG"
}


# EXPORT ALL THE VARIABLES FROM THE ANSWERS FILE
set -o allexport
source answers.txt
set +o allexport

deploy
