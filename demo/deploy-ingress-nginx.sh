#!/bin/bash

set -aueo pipefail

# shellcheck disable=SC1091
source .env


MESH_NAME="${MESH_NAME:-osm-edge}"
K8S_NAMESPACE="${K8S_NAMESPACE:-osm-edge-system}"
NGINX_NAMESPACE="ingress-nginx"

helm upgrade --install ingress-nginx ingress-nginx \
  --repo https://kubernetes.github.io/ingress-nginx \
  --namespace $NGINX_NAMESPACE --create-namespace \
  --set controller.service.httpPort.port="82"


nginx_ingress_namespace=$NGINX_NAMESPACE
nginx_ingress_service="ingress-nginx-controller"
nginx_ingress_host="$(kubectl -n "$nginx_ingress_namespace" get service "$nginx_ingress_service" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
nginx_ingress_port="$(kubectl -n "$nginx_ingress_namespace" get service "$nginx_ingress_service" -o jsonpath='{.spec.ports[?(@.name=="http")].port}')"

osm namespace add "$nginx_ingress_namespace" --mesh-name "$MESH_NAME" --disable-sidecar-injection

kubectl apply -f - <<EOF
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: nginx-echo-ingress
  namespace: echo-consumer
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - backend:
          service:
            name: echo-http-consumer-v1
            port:
              number: 8090
        path: /httpEcho
        pathType: Prefix
      - backend:
          service:
            name: echo-grpc-consumer-v1
            port:
              number: 8090
        path: /grpcEcho
        pathType: Prefix
      - backend:
          service:
            name: echo-dubbo-consumer-v1
            port:
              number: 8090
        path: /dubboEcho
        pathType: Prefix

---
kind: IngressBackend
apiVersion: policy.openservicemesh.io/v1alpha1
metadata:
  name: nginx-echo-ingress-backend
  namespace: echo-consumer
spec:
  backends:
  - name: echo-http-consumer-v1
    port:
      number: 8090
      protocol: http
  - name: echo-grpc-consumer-v1
    port:
      number: 8090
      protocol: http
  - name: echo-dubbo-consumer-v1
    port:
      number: 8090
      protocol: http
  sources:
  - kind: Service
    namespace: "$nginx_ingress_namespace"
    name: "$nginx_ingress_service"
EOF