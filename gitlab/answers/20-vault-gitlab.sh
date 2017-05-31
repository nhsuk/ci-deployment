#!/bin/bash

# CHECK RANCER_SERVER ENV EXISTS
if [ -z "$VAULT_SERVER" ]; then
  echo "VAULT_SERVER not set, skipping vault config"
  SKIP="1"
fi

# CHECK RANCER_SERVER ENV EXISTS
if [ -z "$VAULT_TOKEN" ]; then
  echo "VAULT_TOKEN not set, skipping vault config"
  SKIP="1"
fi

if [ "$SKIP" != "1" ]; then

  if [ "$REVIEW_APP" == "TRUE" ]; then
    ENVIRONMENT="review"
  else
    ENVIRONMENT="$CI_ENVIRONMENT_NAME"
  fi


  # GET COMMON VARIABLES
  VAULT_PATH="/v1/secret/common"

  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -H "X-Vault-Token: ${VAULT_TOKEN}" -X GET https://${VAULT_SERVER}${VAULT_PATH})
  echo "Retrieving common variables from path: ${VAULT_PATH}. Status ${HTTP_STATUS}"
  DATA=$( curl -s  \
      -H "X-Vault-Token: ${VAULT_TOKEN}" \
      -X GET \
      https://${VAULT_SERVER}${VAULT_PATH} \
  )
  echo "$DATA" | jq -r '.data | to_entries[] | (.key+"=\""+.value+"\"")' >> answers.txt


  # GET ENVIRONMENT COMMON VARIABLES
  VAULT_PATH="/v1/secret/${ENVIRONMENT}/common"

  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -H "X-Vault-Token: ${VAULT_TOKEN}" -X GET https://${VAULT_SERVER}${VAULT_PATH})
  echo "Retrieving common environment variables from path: ${VAULT_PATH}. Status ${HTTP_STATUS}"
  DATA=$( curl -s \
      -H "X-Vault-Token: ${VAULT_TOKEN}" \
      -X GET \
      https://${VAULT_SERVER}${VAULT_PATH} \
  )
  echo "$DATA" | jq -r '.data | to_entries[] | (.key+"=\""+.value+"\"")' >> answers.txt


  # GET APPLICATION VARIABLES (COMMON ACROSS ALL ENVIRIONMENTS)
  # IF AVAILABLE
  VAULT_PATH="/v1/secret/common/${CI_PROJECT_NAME}/env-vars"

  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -H "X-Vault-Token: ${VAULT_TOKEN}" -X GET https://${VAULT_SERVER}${VAULT_PATH})
  if [ "$HTTP_STATUS" = "200" ]; then
    echo "Retrieving application specific variables from path: ${VAULT_PATH}. Status ${HTTP_STATUS}"
    DATA=$( curl -s \
        -H "X-Vault-Token: ${VAULT_TOKEN}" \
        -X GET \
        https://${VAULT_SERVER}${VAULT_PATH} \
    )
    echo "$DATA" | jq -r '.data | to_entries[] | (.key+"=\""+.value+"\"")' >> answers.txt
  fi


  # GET APPLICATION SPECIFIC VARIABLES
  VAULT_PATH="/v1/secret/${ENVIRONMENT}/${CI_PROJECT_NAME}/env-vars"

  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -H "X-Vault-Token: ${VAULT_TOKEN}" -X GET https://${VAULT_SERVER}${VAULT_PATH})
  echo "Retrieving application specific variables from path: ${VAULT_PATH}. Status ${HTTP_STATUS}"
  DATA=$( curl -s \
      -H "X-Vault-Token: ${VAULT_TOKEN}" \
      -X GET \
      https://${VAULT_SERVER}${VAULT_PATH} \
  )
  echo "$DATA" | jq -r '.data | to_entries[] | (.key+"=\""+.value+"\"")' >> answers.txt

fi
