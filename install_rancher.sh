#!/usr/bin/env bash

declare -r RANCHER_CLI_VERSION='v0.5.0'
declare OS; OS="$1"

mkdir tmp bin
curl -sL "https://github.com/rancher/cli/releases/download/${RANCHER_CLI_VERSION}/rancher-${OS}-amd64-${RANCHER_CLI_VERSION}.tar.gz" | tar xvz -C tmp
mv tmp/rancher-${RANCHER_CLI_VERSION}/rancher bin/rancher
chmod +x bin/rancher
rm -r tmp/rancher-${RANCHER_CLI_VERSION}
PATH=$PATH:./bin
