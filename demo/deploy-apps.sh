#!/bin/bash

set -aueo pipefail

# shellcheck disable=SC1091
source .env

./demo/deploy-istio-http-service.sh
./demo/deploy-istio-http-client.sh
./demo/deploy-istio-grpc-service.sh
./demo/deploy-istio-grpc-client.sh
./demo/deploy-istio-dubbo-grpc-service.sh
./demo/deploy-istio-dubbo-grpc-client.sh
./demo/deploy-istio-ingress-pipy.sh