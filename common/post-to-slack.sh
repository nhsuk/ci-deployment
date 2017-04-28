SLACK_TOKEN="$1"
SLACK_CHANNEL_ID="$2"
MSG="$3"

if [ -z "$SLACK_TOKEN" ]; then
  echo "Failed to post comment to slack (SLACK_TOKEN not set)"
fi

SLACK_RESPONSE=$(curl -s --data-urlencode "text=$MSG" "https://slack.com/api/chat.postMessage?token=${SLACK_TOKEN}&channel=${SLACK_CHANNEL_ID}")

# if [ "$(jq '.ok' <<< "${SLACK_RESPONSE}")" == "true" ]; then
#   echo "Comment '${MSG}' posted to slack channel ${SLACK_CHANNEL_ID}"
# else
#   echo "Failed to post comment '${MSG}' slack channel ${SLACK_CHANNEL_ID} (${SLACK_RESPONSE})"
# fi
