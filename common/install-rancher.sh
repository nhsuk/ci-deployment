#!/bin/bash

# CHECK IF RANCHER EXISTS IN PATH
if command -v rancher >/dev/null 2>&1 ; then
  RANCHER_VERSION='v0.6.0-rc2'
  RANCHER_INSTALL_PATH='/tmp/rancher-cli'

  echo "Installing Rancher (${RANCHER_VERSION})"
  curl -Ls https://github.com/rancher/cli/releases/download/${RANCHER_VERSION}/rancher-linux-amd64-${RANCHER_VERSION}.tar.gz \
    | tar xzf -
  mkdir "$RANCHER_INSTALL_PATH"
  mv rancher-${RANCHER_VERSION}/rancher "${RANCHER_INSTALL_PATH}/rancher"
  chmod 755 "${RANCHER_INSTALL_PATH}/rancher"
  export PATH="$PATH:${RANCHER_INSTALL_PATH}"
  rm -r rancher-${RANCHER_VERSION}
fi
