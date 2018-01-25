#!/bin/sh

# SET SOME SANE DEFAULTS
{
  echo "RACHER_SERVER=${RANCHER_SERVER-rancher.nhschoices.net}"
  echo "RANCHER_ENVIRONMENT=${RANCHER_ENVIRONMENT-nhsuk-dev}"
  echo "TRAEFIK_DOMAIN=${TRAEFIK_DOMAIN-dev.beta.nhschoices.net}"
  echo "NOTIFICATION_METHOD=slack"
  echo "WEB_EXPOSE=${WEB_EXPOSE-true}"
} >> answers.txt
