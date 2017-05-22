#!/bin/bash

MSG="$1"

if [ -z "$SLACK_HOOK_URL" ]; then
  echo "Failed to post comment to slack (SLACK_HOOK_URL not set)"
  exit 1
fi

if [ -z "$SLACK_CHANNEL" ]; then
  echo "Failed to post comment to slack (SLACK_CHANNEL not set)"
  exit 1
fi

SLACK_RESPONSE=$(curl -s -X POST --data-urlencode "payload={'channel': '#${SLACK_CHANNEL}', 'text': '${MSG}'}" $SLACK_HOOK_URL)

if echo $SLACK_RESPONSE | grep 'ok'; then
   echo "Comment '${MSG}' posted to slack channel #${SLACK_CHANNEL}"
 else
   echo "Failed to post comment '${MSG}' slack channel ${SLACK_CHANNEL} (${SLACK_RESPONSE})"
 fi
