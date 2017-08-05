#!/bin/bash

PULL_REQUEST="$TRAVIS_PULL_REQUEST"
REPO="$TRAVIS_REPO_SLUG"

if [ -z "$GITHUB_ACCESS_TOKEN" ]; then
  echo "GITHUB_ACCESS_TOKEN not set"
  exit 1
fi


# IF SERVICE IS SET TO EXPOSE, APPEND THE URL TO THE MESSAGE
if [ "$WEB_EXPOSE" = "true" ]; then
  URL="https://$DEPLOY_URL"
else
  URL=""
fi

if [ "$DEPLOYMENT_STATUS" = "successful" ]; then
  MSG=":rocket: deployment of $REPO succeeded $URL"
  STATUS="success"
else
  MSG=":boom: deployment of $REPO failed"
  STATUS="failure"
fi

PULL_REQUESTS_URL="https://api.github.com/repos/${REPO}/pulls/$PULL_REQUEST"
echo "$PULL_REQUESTS_URL"

SHA=$(curl -s "$PULL_REQUESTS_URL"| jq --raw-output '.head.sha')
PAYLOAD="{
  \"state\": \"${STATUS}\",
  \"target_url\": \"${URL}\",
  \"description\": \"Deployment of ${REPO}.\",
  \"context\": \"Deployment/rancher\"
}"

echo "${PAYLOAD}" 
echo "https://api.github.com/repos/${REPO}/statuses/${SHA}"

GITHUB_RESPONSE=$(curl -s -o /dev/null -w '%{http_code}' -d "${PAYLOAD}" "https://api.github.com/repos/${REPO}/statuses/${SHA}?access_token=${GITHUB_ACCESS_TOKEN}")

if [ "${GITHUB_RESPONSE}" = "201" ]; then
  echo "Comment '${MSG}' added to pr ${PULL_REQUEST} on ${REPO}"
else
  echo "Failed to add comment to pr ${PULL_REQUEST} on ${REPO} (response code: \"${GITHUB_RESPONSE}\")"
fi
