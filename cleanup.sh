#!/bin/bash

set -e

echo "=== Cleanup Script ==="
echo ""

echo "Deleting WordPress release..."
helm delete my-release --namespace default || true

echo "Deleting Monitoring stack..."
helm delete monitoring --namespace default || true

echo "Waiting for pods to terminate..."
sleep 10

echo "Deleting PVCs..."
kubectl delete pvc --all --namespace default || true

echo "Deleting PVs..."
kubectl delete pv --all || true

echo ""
echo "=== Cleanup Complete ==="
kubectl get pods
kubectl get pvc
kubectl get services
