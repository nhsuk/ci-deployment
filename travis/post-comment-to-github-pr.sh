#!/bin/bash

PULL_REQUEST="$TRAVIS_PULL_REQUEST"
REPO="$TRAVIS_REPO_SLUG"

if [ -z "$GITHUB_ACCESS_TOKEN" ]; then
  echo "GITHUB_ACCESS_TOKEN not set"
  exit 1
fi

MSG="Deployment of $REPO"
if [ "$DEPLOYMENT_STATUS" = "pending" ]; then
  MSG="$MSG in progress"
  STATUS="$DEPLOYMENT_STATUS"
elif [ "$DEPLOYMENT_STATUS" = "successful" ]; then
  MSG="$MSG succeeded"
  STATUS="success"
elif [ "$DEPLOYMENT_STATUS" = "fail" ]; then
  MSG="$MSG failed"
  STATUS="failure"
else
  exit 1
fi

if [ "$WEB_EXPOSE" = "true" ] && [ "$STATUS" = "success" ]; then
  URL="https://$DEPLOY_URL"
else
  URL=""
fi

PAYLOAD="{
  \"state\": \"${STATUS}\",
  \"target_url\": \"${URL}\",
  \"description\":  \"${MSG}\",
  \"context\": \"deployment/rancher\"
}"

PULL_REQUESTS_URL="https://api.github.com/repos/${REPO}/pulls/$PULL_REQUEST"
SHA=$(curl -s "$PULL_REQUESTS_URL"| jq --raw-output '.head.sha')

GITHUB_RESPONSE=$(curl -s -o /dev/null -w '%{http_code}' -d "${PAYLOAD}" "https://api.github.com/repos/${REPO}/statuses/${SHA}?access_token=${GITHUB_ACCESS_TOKEN}")

if [ "${GITHUB_RESPONSE}" = "201" ]; then
  echo "Comment '${MSG}' added to pr ${PULL_REQUEST} on ${REPO}"
else
  echo "Failed to add comment to pr ${PULL_REQUEST} on ${REPO} (response code: \"${GITHUB_RESPONSE}\")"
fi
