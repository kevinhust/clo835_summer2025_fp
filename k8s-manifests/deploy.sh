#!/bin/bash

# CLO835 Final Project - Manual Kubernetes Deployment Script
# This script deploys the application manually (for local testing)
# GitHub Actions automates this process for CI/CD

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE=${NAMESPACE:-"fp"}
AWS_REGION=${AWS_REGION:-"us-east-1"}

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN} CLO835 Final Project Manual Deployment${NC}"
echo -e "${GREEN}========================================${NC}"
echo

# Check kubectl connectivity
if ! kubectl cluster-info &>/dev/null; then
    echo -e "${RED}Error: Cannot connect to Kubernetes cluster${NC}"
    echo "Please ensure your kubeconfig is properly configured:"
    echo "aws eks update-kubeconfig --region $AWS_REGION --name clo835-eks-cluster"
    exit 1
fi

echo -e "${BLUE}Step 1: Creating namespace${NC}"
kubectl apply -f namespace.yaml

echo -e "${BLUE}Step 2: Creating RBAC resources${NC}"
kubectl apply -f rbac.yaml

echo -e "${BLUE}Step 3: Creating persistent volume claim${NC}"
kubectl apply -f pvc.yaml

echo -e "${BLUE}Step 4: Creating ConfigMap${NC}"
kubectl apply -f configmap.yaml

echo -e "${BLUE}Step 5: Creating Secrets${NC}"
# Note: AWS secrets should be created separately with actual values
echo -e "${YELLOW}Warning: AWS secrets need to be created with actual credentials${NC}"
echo "Run: kubectl create secret generic aws-secret -n $NAMESPACE \\"
echo "  --from-literal=AWS_ACCESS_KEY_ID=your-key \\"
echo "  --from-literal=AWS_SECRET_ACCESS_KEY=your-secret"
kubectl apply -f secrets.yaml

echo -e "${BLUE}Step 6: Deploying MySQL database${NC}"
kubectl apply -f mysql-deployment.yaml
kubectl apply -f mysql-service.yaml

echo -e "${BLUE}Step 7: Waiting for MySQL to be ready...${NC}"
kubectl wait --for=condition=available deployment/mysql-deployment -n $NAMESPACE --timeout=180s

echo -e "${BLUE}Step 8: Deploying webapp${NC}"
kubectl apply -f webapp-deployment.yaml
kubectl apply -f webapp-service.yaml

echo -e "${BLUE}Step 9: Waiting for webapp deployment...${NC}"
kubectl rollout status deployment/webapp-deployment -n $NAMESPACE --timeout=300s

echo -e "${GREEN}Deployment completed successfully!${NC}"
echo
echo -e "${BLUE}Checking deployment status:${NC}"
kubectl get all -n $NAMESPACE

echo
echo -e "${YELLOW}Note: LoadBalancer may take 2-3 minutes to provision external IP${NC}"
echo "Check service status with: kubectl get svc webapp-service -n $NAMESPACE"
echo
echo -e "${GREEN}Manual deployment complete!${NC}"