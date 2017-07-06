#!/bin/bash

if [ -z "$SLACK_HOOK_URL" ]; then
  echo "Failed to post comment to slack (SLACK_HOOK_URL not set)"
  exit 1
fi

if [ -z "$SLACK_CHANNEL" ]; then
  echo "Failed to post comment to slack (SLACK_CHANNEL not set)"
  exit 1
fi

SLACK_PAYLOAD=$(bash ./scripts/ci-deployment/common/slack-msg.sh "$DEPLOYMENT_STATUS")

SLACK_RESPONSE=$(curl -s -X POST --data-urlencode "payload=${SLACK_PAYLOAD}" "$SLACK_HOOK_URL")

if echo "$SLACK_RESPONSE" | grep 'ok'; then
   echo "Comment posted to slack channel #${SLACK_CHANNEL}"
else
   echo "Failed to post comment to slack channel ${SLACK_CHANNEL} (${SLACK_RESPONSE})"
fi
