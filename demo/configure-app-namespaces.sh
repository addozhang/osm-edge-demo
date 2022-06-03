#!/bin/bash

set -aueo pipefail

# shellcheck disable=SC1091
source .env

kubectl create namespace "$TEST_NAMESPACE" --save-config
./scripts/create-container-registry-creds.sh "$TEST_NAMESPACE"

# Add namespaces to the mesh
osm namespace add --mesh-name "$MESH_NAME" "$TEST_NAMESPACE"

# Enable metrics for pods belonging to app namespaces
osm metrics enable --namespace "$TEST_NAMESPACE"
