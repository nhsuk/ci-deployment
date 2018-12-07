#!/bin/bash

# See here http://redsymbol.net/articles/unofficial-bash-strict-mode/ the rational for using u, e and o bash options

set -e          #Exit with error code if any command fails

check_rancher_vars() {

  RANCHER_ENVS="RANCHER_ENVIRONMENT RANCHER_ACCESS_KEY RANCHER_SECRET_KEY"

  for i in $RANCHER_ENVS; do
    VALUE=$(eval "echo \$$i")
    if [ ! -n "$VALUE" ]; then
      echo "RANCHER ENV VARIABLE $i NOT SET!"
      exit 1
    fi
  done

}

#check_rancher_vars

echo "Deploying rancher stack $RANCHER_STACK_NAME in environment $RANCHER_ENVIRONMENT"


# Set RANCHER_URL, doing it here so we can set RANCHER_SERVER in Vault
export RANCHER_URL=https://${RANCHER_SERVER}/v2-beta/schemas

export DEPLOYMENT_STATUS="pending"
if [ "$NOTIFICATION_METHOD" = "github" ]; then
  bash ./scripts/ci-deployment/travis/post-comment-to-github-pr.sh
fi

pushd rancher-config/ > /dev/null


# ACTUALLY DEPLOY NOW (SEE RANCHER UP --HELP)
if ../rancher -w up --force-upgrade -p -d -u -c -s "${RANCHER_STACK_NAME}"; then
  export DEPLOYMENT_STATUS="successful"
else
  export DEPLOYMENT_STATUS="failed"
fi
popd > /dev/null

# SET STACK DESCRIPTION
bash common/set-stack-description.sh "$RANCHER_DESCRIPTION"

# PUSH NOTIFICATION TO SLACK OR GITHUB
if [ "$NOTIFICATION_METHOD" = "slack" ]; then
  bash common/post-comment-to-slack.sh
elif [ "$NOTIFICATION_METHOD" = "github" ]; then
  bash ./scripts/ci-deployment/travis/post-comment-to-github-pr.sh
fi
