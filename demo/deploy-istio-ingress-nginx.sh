#!/bin/bash

set -aueo pipefail

# shellcheck disable=SC1091
source .env


MESH_NAME="${MESH_NAME:-osm-edge}"
K8S_NAMESPACE="${K8S_NAMESPACE:-osm-edge-system}"
NGINX_NAMESPACE="ingress-nginx"
TEST_NAMESPACE="${TEST_NAMESPACE:-sft-test-flomesh}"

SVC_ISTIO_HTTP_CLIENT="istio-http-client"
SVC_ISTIO_GRPC_CLIENT="istio-grpc-client"
SVC_ISTIO_DUBBO_GRPC_CLIENT="istio-dubbo-grpc-client"

helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace $NGINX_NAMESPACE --create-namespace \
  --set controller.service.httpPort.port="82"


nginx_ingress_namespace=$NGINX_NAMESPACE
nginx_ingress_service="ingress-nginx-controller"
nginx_ingress_host="$(kubectl -n "$nginx_ingress_namespace" get service "$nginx_ingress_service" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
nginx_ingress_port="$(kubectl -n "$nginx_ingress_namespace" get service "$nginx_ingress_service" -o jsonpath='{.spec.ports[?(@.name=="http")].port}')"

osm namespace add "$nginx_ingress_namespace" --mesh-name "$MESH_NAME" --disable-sidecar-injection

kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/instance=ingress-nginx \
  --timeout=600s

kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-ingress
  namespace: $TEST_NAMESPACE
spec:
  ingressClassName: nginx
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
  name: nginx-ingress-backend
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
  sources:
  - kind: Service
    namespace: "$nginx_ingress_namespace"
    name: "$nginx_ingress_service"
EOF

echo "ingress deployed"