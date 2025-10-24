#!/bin/bash

set -e

echo "=== WordPress Kubernetes Deployment Script ==="
echo ""

echo "Step 1: Building Docker Images..."
echo "Building MySQL image..."
cd docker/mysql
docker build -t mysql-custom:latest .

echo "Building WordPress image..."
cd ../wordpress
docker build -t wordpress-custom:latest .

echo "Building Nginx OpenResty image..."
cd ../nginx
docker build -t nginx-openresty:latest .

cd ../..

echo ""
echo "Step 2: Deploying WordPress Application..."
cd helm/wordpress
helm install my-release . --namespace default

echo ""
echo "Step 3: Waiting for pods to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=my-release --timeout=300s

echo ""
echo "Step 4: Deploying Monitoring Stack..."
cd ../monitoring
helm dependency update
helm install monitoring . --namespace default

echo ""
echo "Step 5: Waiting for monitoring pods..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus --timeout=300s || true
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana --timeout=300s || true

echo ""
echo "=== Deployment Complete ==="
echo ""
echo "Services:"
kubectl get services

echo ""
echo "Pods:"
kubectl get pods

echo ""
echo "PVCs:"
kubectl get pvc

echo ""
echo "=== Access Information ==="
echo "WordPress: http://$(kubectl get service my-release-wordpress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo '<pending>')"
echo "Grafana: http://$(kubectl get service monitoring-grafana -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo '<pending>')"
echo "Grafana credentials: admin/admin"
