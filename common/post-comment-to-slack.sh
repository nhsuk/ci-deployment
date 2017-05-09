#!/bin/bash

MSG="$1"

if [ -z "$SLACK_TOKEN" ]; then
  echo "Failed to post comment to slack (SLACK_TOKEN not set)"
  exit 1
fi

if [ -z "$SLACK_CHANNEL_ID" ]; then
  echo "Failed to post comment to slack (SLACK_CHANNEL_ID not set)"
  exit 1
fi

SLACK_RESPONSE=$(curl -s --data-urlencode "text=$MSG" "https://slack.com/api/chat.postMessage?token=${SLACK_TOKEN}&channel=${SLACK_CHANNEL_ID}")

if echo $SLACK_RESPONSE | grep -q '"ok":true'; then
   echo "Comment '${MSG}' posted to slack channel ${SLACK_CHANNEL_ID}"
 else
   echo "Failed to post comment '${MSG}' slack channel ${SLACK_CHANNEL_ID} (${SLACK_RESPONSE})"
 fi
