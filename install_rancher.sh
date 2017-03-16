#!/usr/bin/env bash

declare -r RANCHER_CLI_VERSION='v0.5.0'
declare OS; OS=$(uname | tr '[:upper:]' '[:lower:]')
declare -r URL="https://github.com/rancher/cli/releases/download/${RANCHER_CLI_VERSION}/rancher-${OS}-amd64-${RANCHER_CLI_VERSION}.tar.gz"
declare BIN="${1:-./bin}"
declare TMP="./tmp"

mkdir -p "$TMP" "$BIN"

echo "installing rancher $RANCHER_CLI_VERSION from $URL into $BIN"

curl -sL "$URL" | tar xvz -C "$TMP" 
mv "$TMP/rancher-${RANCHER_CLI_VERSION}/rancher" "$BIN/rancher"
chmod +x "$BIN/rancher"
rm -r "$TMP/rancher-${RANCHER_CLI_VERSION}"
PATH="$PATH:$BIN"
