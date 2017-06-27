#!/bin/bash

DEPLOYMENT_STATUS="$1"

if [ "$TRAVIS" = "true" ]; then
  PROJECT_NAME="$REPO_NAME"
elif [ -n "$GITLAB_CI" ]; then
  PROJECT_NAME="$CI_PROJECT_NAME"
elif [ -n "$TEAMCITY_VERSION" ]; then
  PROJECT_NAME="$TEAMCITY_PROJECT_NAME"
fi

if [ "$DEPLOYMENT_STATUS" = "true" ]; then
  MSG=":rocket: deployment of $PROJECT_NAME succeeded (http://$DEPLOY_URL)"
else
  MSG=":warning: deployment of $PROJECT_NAME failed"
fi

echo "$MSG"
