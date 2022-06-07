#!/bin/bash
POD=$(kubectl get pods -n osm-edge-system -l app=osm-controller -o jsonpath='{.items[0].metadata.name}')
kubectl logs -n osm-edge-system -f $POD
