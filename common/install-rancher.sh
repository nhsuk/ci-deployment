#!/bin/bash

if [ ! -f "./rancher" ] ; then
  RANCHER_VERSION='v0.6.1'

  echo "Installing Rancher (${RANCHER_VERSION})"
  curl -Ls https://github.com/rancher/cli/releases/download/${RANCHER_VERSION}/rancher-linux-amd64-${RANCHER_VERSION}.tar.gz \
    | tar xzf -
  mv rancher-${RANCHER_VERSION}/rancher ./rancher
  rm -r rancher-${RANCHER_VERSION}
fi
