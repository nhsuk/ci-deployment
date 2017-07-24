#!/bin/bash

# See here http://redsymbol.net/articles/unofficial-bash-strict-mode/ the rational for using u, e and o bash options

set -e          #Exit with error code if any command fails

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

check_rancher_vars

echo "Deploying rancher stack $RANCHER_STACK_NAME in environment $RANCHER_ENVIRONMENT"

pushd rancher-config/ > /dev/null
# ACTUALLY DEPLOY NOW
# shellcheck disable=SC2034
../rancher \
  --wait \
    up  -p \
        -d \
        --upgrade \
        --force-upgrade \
        --confirm-upgrade \
        --stack "${RANCHER_STACK_NAME}"

# shellcheck disable=SC2181
if [ $? -eq 0 ]; then
  export DEPLOYMENT_STATUS="successful"
else
  export DEPLOYMENT_STATUS="failed"
fi
popd > /dev/null

# SET STACK DESCRIPTION
bash ./scripts/ci-deployment/common/set-stack-description.sh "$RANCHER_DESCRIPTION"

# PUSH NOTIFICATION TO SLACK OR GITHUB
if [ "$NOTIFICATION_METHOD" = "slack" ]; then
  bash ./scripts/ci-deployment/common/post-comment-to-slack.sh
elif [ "$NOTIFICATION_METHOD" = "github" ]; then
  bash ./scripts/ci-deployment/travis/post-comment-to-github-pr.sh
fi
