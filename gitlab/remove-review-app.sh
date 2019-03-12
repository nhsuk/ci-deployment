#!/bin/sh

check_rancher_vars() {

  RANCHER_ENVS="RANCHER_ENVIRONMENT RANCHER_ACCESS_KEY RANCHER_SECRET_KEY"

  for i in $RANCHER_ENVS; do
    VALUE=$(eval "echo \$$i")
    if [ ! -n "$VALUE" ]; then
      echo "RANCHER ENV VARIABLE $i NOT SET!"
      exit 1
    fi
  done

}

bash ./scripts/ci-deployment/common/install-rancher.sh
bash ./scripts/ci-deployment/common/generate-answers.sh

# EXPORT ALL THE VARIABLES FROM THE GENERATED ANSWERS FILE
set -o allexport
# shellcheck source=/dev/null
. answers.txt
set +o allexport



# REMOVE RANCHER ENVIRONMENT

check_rancher_vars

# Set RANCHER_URL, doing it here so we can set RANCHER_SERVER in Vault
export RANCHER_URL=https://${RANCHER_SERVER}/v2-beta/schemas

./rancher --wait rm "${RANCHER_STACK_NAME}"

# RUN REPO SPECIFIC REMOVAL SCRIPTS, IF DIRECTORY EXISTS
if [ -d "./scripts/removal_scripts" ]; then
  for f in ./scripts/removal_scripts/*; do
    echo "Running script: $f"
    # shellcheck source=/dev/null
    . "$f"
  done
fi
