#!/bin/bash

set -euo pipefail

if [ -z "$1" ]; then
  echo "Error: expected one argument OS_ARCH"
  exit 1
fi

if [ -z "$2" ]; then
  echo "Error: expected one argument OS"
  exit 1
fi

BUILD_ARCH=$1
BUILD_OS=$2

rm -rf ./osm-edge-v1.1.0-${BUILD_OS}-${BUILD_ARCH}.tar.gz
sudo axel https://github.com/flomesh-io/osm-edge/releases/download/v1.1.0/osm-edge-v1.1.0-${BUILD_OS}-${BUILD_ARCH}.tar.gz
mkdir -p /tmp/osm-cli
tar zxf ./osm-edge-v1.1.0-${BUILD_OS}-${BUILD_ARCH}.tar.gz -C /tmp/osm-cli
cp -rf /tmp/osm-cli/linux-${BUILD_ARCH}/osm /usr/local/sbin/osm
rm -rf /tmp/osm-cli
rm -rf osm-edge-v1.1.0-${BUILD_OS}-${BUILD_ARCH}.tar.gz
sudo chmod a+x /usr/local/sbin/osm