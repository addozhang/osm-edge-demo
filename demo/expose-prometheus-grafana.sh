
#!/bin/bash

set -aueo pipefail

# shellcheck disable=SC1091
source .env

kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  labels:
    app: osm-grafana
  name: osm-grafana-host
  namespace: $K8S_NAMESPACE
spec:
  ports:
  - port: 3000
    protocol: TCP
    targetPort: 3000
    nodePort: 30030
  selector:
    app: osm-grafana
  type: NodePort
EOF

kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: osm-prometheus-host
  namespace: $K8S_NAMESPACE
spec:
  ports:
  - port: 7070
    protocol: TCP
    targetPort: 7070
    nodePort: 30070
  selector:
    app: osm-prometheus
  type: NodePort
EOF