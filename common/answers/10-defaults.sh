#!/bin/sh

# SET SOME SANE DEFAULTS
{
  echo "RACHER_SERVER=${RANCHER_SERVER-rancher.nhschoices.net}"
  echo "RANCHER_URL=https://${RANCHER_SERVER-rancher.nhschoices.net}/v2-beta/schemas"
  echo "RANCHER_ENVIRONMENT=${RANCHER_ENVIRONMENT-nhsuk-dev}"
  echo "TRAEFIK_DOMAIN=${TRAEFIK_DOMAIN-dev.beta.nhschoices.net}"
  echo "NOTIFICATION_METHOD=slack"
} >> answers.txt
