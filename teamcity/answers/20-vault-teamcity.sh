#!/bin/bash

get_vault_data() {

  VAULT_PATH = "$1"

  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" -H "X-Vault-Token: ${VAULT_TOKEN}" -X GET "https://${VAULT_SERVER}${VAULT_PATH}")
  echo "Retrieving default variables from path: ${VAULT_PATH}. Status ${HTTP_STATUS}"
  if [ "$HTTP_STATUS" = "200" ]; then
    DATA=$( curl -s  \
        -H "X-Vault-Token: ${VAULT_TOKEN}" \
        -X GET \
        "https://${VAULT_SERVER}${VAULT_PATH}" \
    )
  fi
  echo "$DATA" | jq -r '.data | to_entries[] | (.key+"=\""+.value+"\"")' >> answers.txt

}

# CHECK RANCHER_SERVER ENV EXISTS
if [ -z "$VAULT_SERVER" ]; then
  echo "VAULT_SERVER not set, skipping vault config"
  SKIP="1"
fi

# CHECK RANCHER_SERVER ENV EXISTS
if [ -z "$VAULT_TOKEN" ]; then
  echo "VAULT_TOKEN not set, skipping vault config"
  SKIP="1"
fi

if [ "$SKIP" != "1" ]; then

  ENVIRONMENT="$CI_ENVIRONMENT_NAME"


  # GET DEFAULT VARIABLES
  VAULT_PATH="/v1/secret/defaults"
  get_vault_data("$VAULT_PATH")

  # GET ENVIRONMENT COMMON VARIABLES
  VAULT_PATH="/v1/secret/${ENVIRONMENT}/defaults"
  get_vault_data("$VAULT_PATH")

  # GET APPLICATION VARIABLES (DEFAULTS)
  # IF AVAILABLE
  VAULT_PATH="/v1/secret/defaults/${TEAMCITY_PROJECT_NAME}/env-vars"
  get_vault_data("$VAULT_PATH")

  # GET APPLICATION VARIABLES (ENVIRONMENT SPECIFIC)
  VAULT_PATH="/v1/secret/${ENVIRONMENT}/${TEAMCITY_PROJECT_NAME}/env-vars"
  get_vault_data("$VAULT_PATH")

fi
