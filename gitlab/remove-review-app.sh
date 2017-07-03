#!/bin/sh

check_rancher_vars() {

  RANCHER_ENVS="RANCHER_URL RANCHER_ENVIRONMENT RANCHER_ACCESS_KEY RANCHER_SECRET_KEY"

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
source answers.txt
set +o allexport

check_rancher_vars

rancher --wait rm "${RANCHER_STACK_NAME}"
