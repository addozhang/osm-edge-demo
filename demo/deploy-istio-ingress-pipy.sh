#!/bin/bash

set -auo pipefail

# shellcheck disable=SC1091
source .env
MESH_NAME="${MESH_NAME:-osm-edge}"
INGRESS_PIPY_NAMESPACE="${INGRESS_PIPY_NAMESPACE:-flomesh}"
PIPY_INGRESS_SERVICE=${PIPY_INGRESS_SERVICE:-ingress-pipy-controller}
TEST_NAMESPACE="${TEST_NAMESPACE:-sft-test-flomesh}"

SVC_ISTIO_HTTP_CLIENT="istio-http-client"
SVC_ISTIO_GRPC_CLIENT="istio-grpc-client"
SVC_ISTIO_DUBBO_GRPC_CLIENT="istio-dubbo-grpc-client"

K8S_INGRESS_NODE="${K8S_INGRESS_NODE:-osm-worker}"

kubectl label node "$K8S_INGRESS_NODE" ingress-ready=true --overwrite=true

helm repo add fsm https://flomesh-io.github.io/fsm

helm install fsm fsm/fsm --namespace "$INGRESS_PIPY_NAMESPACE" --create-namespace
sleep 5

kubectl wait --namespace "$INGRESS_PIPY_NAMESPACE" \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/instance=ingress-pipy \
  --timeout=600s

kubectl patch deployment -n "$INGRESS_PIPY_NAMESPACE" ingress-pipy -p \
'{
  "spec": {
    "template": {
      "spec": {
        "containers": [
          {
            "name": "ingress",
            "ports": [
              {
                "containerPort": 8000,
                "hostPort": 81,
                "name": "ingress",
                "protocol": "TCP"
              }
            ]
          }
        ],
        "nodeSelector": {
          "ingress-ready": "true"
        }
      }
    }
  }
}'

kubectl wait --namespace "$INGRESS_PIPY_NAMESPACE" \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/instance=ingress-pipy \
  --timeout=600s

kubectl patch service -n "$INGRESS_PIPY_NAMESPACE" "$PIPY_INGRESS_SERVICE" -p '{"spec":{"type":"NodePort"}}'

osm namespace add "$INGRESS_PIPY_NAMESPACE" --mesh-name "$MESH_NAME" --disable-sidecar-injection

kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: pipy-ingress
  namespace: $TEST_NAMESPACE
spec:
  ingressClassName: pipy
  rules:
  - http:
      paths:
      - path: /hi
        pathType: Prefix
        backend:
          service:
            name: $SVC_ISTIO_HTTP_CLIENT
            port:
              number: 8080
      - path: /hello
        pathType: Prefix
        backend:
          service:
            name: $SVC_ISTIO_GRPC_CLIENT
            port:
              number: 8080
      - path: /dubbo/*
        pathType: Prefix
        backend:
          service:
            name: $SVC_ISTIO_DUBBO_GRPC_CLIENT
            port:
              number: 8080
---
kind: IngressBackend
apiVersion: policy.openservicemesh.io/v1alpha1
metadata:
  name: pipy-ingress-backend
  namespace: $TEST_NAMESPACE
spec:
  backends:
  - name: $SVC_ISTIO_HTTP_CLIENT
    port:
      number: 8080
      protocol: http
  - name: $SVC_ISTIO_GRPC_CLIENT
    port:
      number: 8080
      protocol: http
  - name: $SVC_ISTIO_DUBBO_GRPC_CLIENT
    port:
      number: 8080
      protocol: http
  sources:
  - kind: Service
    namespace: "$INGRESS_PIPY_NAMESPACE"
    name: "$PIPY_INGRESS_SERVICE"
EOF
