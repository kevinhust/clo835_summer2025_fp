#!/bin/bash

# CLO835 Final Project - Kubernetes Cleanup Script
# This script removes all deployed resources from the EKS cluster

set -e

echo "🧹 Starting CLO835 Final Project Cleanup..."

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

# Check if namespace exists
if kubectl get namespace fp &> /dev/null; then
    echo "📦 Found 'fp' namespace. Proceeding with cleanup..."
    
    echo "🗑️  Deleting all resources in 'fp' namespace..."
    kubectl delete namespace fp
    
    echo "⏳ Waiting for namespace deletion to complete..."
    while kubectl get namespace fp &> /dev/null; do
        echo "   Still deleting..."
        sleep 5
    done
    
    echo "✅ Namespace 'fp' and all resources have been deleted successfully!"
else
    echo "ℹ️  Namespace 'fp' not found. Nothing to clean up."
fi

echo ""
echo "🎉 Cleanup completed successfully!"
echo ""
echo "📊 Verifying cleanup:"
kubectl get namespace | grep -E "(NAME|fp)" || echo "✅ 'fp' namespace successfully removed"

echo ""
echo "💡 Note: If you had any LoadBalancer services, the associated AWS Load Balancers"
echo "   should be automatically deleted, but you may want to verify in the AWS console."