#!/usr/bin/env bash
set -euo pipefail

# This script prepares manifests with a dynamic ECR URL and applies them.
# Prereqs: aws cli, kubectl, env AWS_REGION exported or defaults to us-east-1

AWS_REGION=${AWS_REGION:-us-east-1}
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_URL="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/clo835fp-webapp"

echo "Using ECR: ${ECR_URL}"

TMP_DIR=$(mktemp -d)
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

# Prepare deployment with injected image URL
sed "s#__ECR_URL__#${ECR_URL}#g" webapp-deployment.yaml > "${TMP_DIR}/webapp-deployment.yaml"

echo "Applying resources to cluster..."
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f rbac.yaml
kubectl apply -f pvc.yaml
kubectl apply -f mysql-deployment.yaml
kubectl apply -f mysql-service.yaml
kubectl apply -f "${TMP_DIR}/webapp-deployment.yaml"
kubectl apply -f webapp-service.yaml
kubectl apply -f webapp-hpa.yaml

echo "Deployment applied. Current status:"
kubectl get all -n fp | cat


