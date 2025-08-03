#!/bin/bash

# CLO835 Final Project - Kubernetes Deployment Script
# This script deploys all Kubernetes manifests to the EKS cluster

set -e

echo "🚀 Starting CLO835 Final Project Deployment..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

# Check if we can connect to the cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Unable to connect to Kubernetes cluster. Please check your kubeconfig."
    exit 1
fi

echo "✅ kubectl is configured and cluster is accessible"

# Deploy manifests in order
echo "📦 Deploying namespace..."
kubectl apply -f namespace.yaml

echo "📦 Deploying ConfigMap..."
kubectl apply -f configmap.yaml

echo "📦 Deploying Secrets..."
kubectl apply -f secrets.yaml

echo "📦 Deploying RBAC resources..."
kubectl apply -f rbac.yaml

echo "📦 Deploying PersistentVolumeClaim..."
kubectl apply -f pvc.yaml

echo "📦 Deploying MySQL database..."
kubectl apply -f mysql-deployment.yaml
kubectl apply -f mysql-service.yaml

# Wait for MySQL to be ready
echo "⏳ Waiting for MySQL to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/mysql-deployment -n fp

echo "📦 Deploying Flask web application..."
kubectl apply -f webapp-deployment.yaml
kubectl apply -f webapp-service.yaml

# Wait for webapp to be ready
echo "⏳ Waiting for webapp to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/webapp-deployment -n fp

echo ""
echo "🎉 Deployment completed successfully!"
echo ""
echo "📊 Current status:"
kubectl get all -n fp

echo ""
echo "🌐 Getting LoadBalancer external IP (may take a few minutes)..."
echo "Run the following command to get the external IP when ready:"
echo "kubectl get service webapp-service -n fp"

echo ""
echo "📝 Next steps:"
echo "1. Wait for LoadBalancer to assign external IP"
echo "2. Initialize MySQL database with employee table"
echo "3. Test the application at the external IP"

echo ""
echo "🔍 Useful monitoring commands:"
echo "kubectl logs -f deployment/webapp-deployment -n fp"
echo "kubectl logs -f deployment/mysql-deployment -n fp"
echo "kubectl get events -n fp --sort-by='.lastTimestamp'"