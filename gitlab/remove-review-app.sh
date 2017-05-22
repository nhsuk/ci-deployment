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

check_rancher_vars

export RANCHER_URL="https://${RANCHER_SERVER}/v2-beta/schemas"
RANCHER_STACK_NAME="${CI_PROJECT_NAME}-${CI_COMMIT_REF_SLUG}"

rancher --wait rm "${RANCHER_STACK_NAME}"
