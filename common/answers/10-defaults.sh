#!/bin/sh

# SET SOME SANE DEFAULTS
{
  echo "RACHER_SERVER=${RANCHER_SERVER-rancher.nhswebsite-staging.nhs.uk}"
  echo "RANCHER_ENVIRONMENT=${RANCHER_ENVIRONMENT-nhsuk-dev}"
  echo "TRAEFIK_DOMAIN=${TRAEFIK_DOMAIN-nhswebsite-integration.nhs.uk}"
  echo "NOTIFICATION_METHOD=slack"
  echo "WEB_EXPOSE=${WEB_EXPOSE-true}"
} >> answers.txt
