#!/bin/bash
POD=$(kubectl get pods -n osm-edge-system -l app=osm-controller -o jsonpath='{.items[0].metadata.name}')
kubectl -n osm-edge-system delete pod $POD
