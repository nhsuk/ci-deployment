#!/bin/bash

if [ "$DEPLOYMENT_STATUS" = "successful" ]; then
  MSG=":rocket: Deployment Succeeded"
  COLOR="good"
else
  MSG=":warning: Deployment failed"
  COLOR="danger"
fi

read -r -d '' SLACK_PAYLOAD << EOM
{
    "channel": "${SLACK_CHANNEL}",
    "text": "$MSG",
    "attachments": [
        {
            "fallback": "$MSG",
            "color": "$COLOR",
            "fields": [
                {
                    "title": "Application",
                    "value": "$PROJECT_NAME",
                    "short": true
                },
                {
                    "title": "Version",
                    "value": "$DOCKER_IMAGE_TAG",
                    "short": true
                },
                {
                    "title": "Environment",
                    "value": "$RANCHER_ENVIRONMENT",
                    "short": true
                },
                {
                    "title": "Environment URL",
                    "value": "$DEPLOY_URL",
                    "short": true
                }
            ]
        }
    ]
}
EOM


echo "$SLACK_PAYLOAD"
