#!/bin/bash

RANCHER_DESCRIPTION="$1"

# GET ENVIRONMENT ID
DATA=$(curl -s -u "${RANCHER_ACCESS_KEY}:${RANCHER_SECRET_KEY}" \
  -X GET \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  "https://${RANCHER_SERVER}/v2-beta/projects" \
  )
RANCHER_ENVIRONMENT_ID=$(echo $DATA | jq --raw-output ".data[] | select(.name==\"${RANCHER_ENVIRONMENT}\") | .id")

# GET STACK ID
DATA=$(curl -s -u "${RANCHER_ACCESS_KEY}:${RANCHER_SECRET_KEY}" \
  -X GET \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  "https://${RANCHER_SERVER}/v2-beta/projects/${RANCHER_ENVIRONMENT_ID}/stacks?name=${RANCHER_STACK_NAME}" \
  )
STACK_ID=$(echo $DATA | jq --raw-output '.data[].id')

# UPDATE RANCHER DESCRIPTION
curl -s -u "${RANCHER_ACCESS_KEY}:${RANCHER_SECRET_KEY}" \
  -X PUT \
  -H 'Accept: application/json' \
  -H 'Content-Type: application/json' \
  -d "{\"description\":\"${RANCHER_DESCRIPTION}\"}" \
  "https://${RANCHER_SERVER}/v2-beta/projects/${RANCHER_ENVIRONMENT_ID}/stacks/${STACK_ID}"
