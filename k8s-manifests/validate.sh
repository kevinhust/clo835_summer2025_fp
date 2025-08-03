#!/bin/bash

# CLO835 Final Project - Kubernetes Manifest Validation Script
# This script validates all Kubernetes manifests before deployment

set -e

echo "🔍 Validating CLO835 Final Project Kubernetes Manifests..."

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed or not in PATH"
    exit 1
fi

# Function to validate a manifest file
validate_manifest() {
    local file=$1
    echo "📋 Validating $file..."
    
    if kubectl apply --dry-run=client -f "$file" &> /dev/null; then
        echo "   ✅ $file is valid"
    else
        echo "   ❌ $file has validation errors:"
        kubectl apply --dry-run=client -f "$file"
        return 1
    fi
}

# List of manifest files in deployment order
MANIFESTS=(
    "namespace.yaml"
    "configmap.yaml"
    "secrets.yaml"
    "rbac.yaml"
    "pvc.yaml"
    "mysql-deployment.yaml"
    "mysql-service.yaml"
    "webapp-deployment.yaml"
    "webapp-service.yaml"
)

# Validate each manifest
validation_failed=false
for manifest in "${MANIFESTS[@]}"; do
    if [[ -f "$manifest" ]]; then
        if ! validate_manifest "$manifest"; then
            validation_failed=true
        fi
    else
        echo "❌ Missing manifest file: $manifest"
        validation_failed=true
    fi
done

echo ""
if [[ "$validation_failed" == "true" ]]; then
    echo "❌ Validation failed! Please fix the errors above before deploying."
    exit 1
else
    echo "🎉 All manifests are valid and ready for deployment!"
fi

echo ""
echo "📋 Deployment checklist:"
echo "□ Update ECR image URI in webapp-deployment.yaml"
echo "□ Update S3 bucket URL in configmap.yaml"
echo "□ Update group name and slogan in configmap.yaml"
echo "□ Update base64 encoded secrets in secrets.yaml"
echo "□ Ensure ECR repository exists and image is pushed"
echo "□ Ensure S3 bucket exists and background image is uploaded"
echo "□ Ensure AWS credentials have S3 access permissions"

echo ""
echo "🚀 Ready to deploy? Run: ./deploy.sh"