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

deploy() {

  check_rancher_vars

  echo "Building rancher stack $RANCHER_STACK_NAME in environment $RANCHER_ENVIRONMENT"

  pushd rancher-config/ > /dev/null
  # ACTUALLY DEPLOY NOW
  ../rancher \
    --wait \
      up  -p \
          -d \
          --upgrade \
          --force-upgrade \
          --confirm-upgrade \
          --stack "${RANCHER_STACK_NAME}"

  if [ $? -eq 0 ]; then
    DEPLOYMENT_SUCCEEDED="true"
  else
    DEPLOYMENT_SUCCEEDED="false"
  fi
  popd > /dev/null

  # SET STACK DESCRIPTION
  bash ./scripts/ci-deployment/common/set-stack-description.sh "$RANCHER_DESCRIPTION"

  # PUSH NOTIFICATION TO SLACK OR GITHUB
  MSG=$(bash ./scripts/ci-deployment/common/deployment-msg.sh "$DEPLOYMENT_SUCCEEDED")
  echo "$MSG"
  if [ "$NOTIFY_METHOD" = "slack" ]; then
    bash ./scripts/ci-deployment/common/post-comment-to-slack.sh "$MSG"
  elif [ "$NOTIFY_METHOD" = "github" ]; then
    bash ./scripts/ci-deployment/travis/post-comment-to-github-pr.sh "$MSG"
  fi

}


# TRAVIS: ONLY DEPLOY ON PRS AND MASTER
if [ "$TRAVIS" = "true" ]; then
  if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then
    export NOTIFY_METHOD="github"
    deploy
  elif [ "$TRAVIS_BRANCH" = "master" ]; then
    export NOTIFY_METHOD="slack"
    deploy
  fi
# GITLAB CI: THIS WILL HAVE BEEN TRIGGERED, SO ALWAYS DEPLOY
elif [ -n "$GITLAB_CI" ]; then
  export NOTIFY_METHOD="slack"
  deploy
# TEAMCITY: USED TO PROMOTE RELEASES TO STAGING/PRODUCTION
elif [ -n "$TEAMCITY_VERSION" ]; then
  export NOTIFY_METHOD="slack"
  deploy
fi
