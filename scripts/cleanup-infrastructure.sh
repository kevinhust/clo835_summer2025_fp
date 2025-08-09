#!/bin/bash

# CLO835 Final Project - Infrastructure Cleanup Script
# This script removes all AWS resources created for the project

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}CLO835 Final Project - Infrastructure Cleanup${NC}"
echo -e "${RED}WARNING: This will delete all AWS resources for the project!${NC}"
echo

# Configuration
REGION=${AWS_REGION:-"us-east-1"}
S3_BUCKET=${S3_BUCKET_NAME:-"clo835fp-bg-images"}
ECR_REPOSITORY=${ECR_REPOSITORY:-"clo835fp-webapp"}
CLUSTER_NAME=${CLUSTER_NAME:-"clo835-eks-cluster"}

echo -e "${YELLOW}Resources to be deleted:${NC}"
echo "- S3 Bucket: $S3_BUCKET"
echo "- ECR Repository: $ECR_REPOSITORY"
echo "- EKS Cluster: $CLUSTER_NAME"
echo

echo "Are you sure you want to proceed? (type 'yes' to confirm)"
read -r confirmation
if [[ "$confirmation" != "yes" ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

# Step 1: Delete Kubernetes resources
echo -e "${BLUE}Step 1: Cleaning up Kubernetes resources${NC}"
if kubectl get namespace fp &>/dev/null; then
    echo "Deleting all resources in namespace 'fp'..."
    kubectl delete all --all -n fp --timeout=300s || true
    kubectl delete pvc --all -n fp --timeout=300s || true
    kubectl delete secrets --all -n fp --timeout=300s || true
    kubectl delete configmaps --all -n fp --timeout=300s || true
    kubectl delete serviceaccounts --all -n fp --timeout=300s || true
    kubectl delete roles --all -n fp --timeout=300s || true
    kubectl delete rolebindings --all -n fp --timeout=300s || true
    
    echo "Waiting for resources to be deleted..."
    sleep 30
    
    kubectl delete namespace fp --timeout=300s || true
    echo "Kubernetes resources cleaned up"
else
    echo "Namespace 'fp' does not exist"
fi
echo

# Step 2: Delete EKS cluster
echo -e "${BLUE}Step 2: Deleting EKS cluster${NC}"
if eksctl get cluster --name "$CLUSTER_NAME" --region "$REGION" &>/dev/null; then
    echo "Deleting EKS cluster $CLUSTER_NAME..."
    echo "This may take 10-15 minutes..."
    eksctl delete cluster --name "$CLUSTER_NAME" --region "$REGION" --wait
    echo "EKS cluster deleted successfully"
else
    echo "EKS cluster $CLUSTER_NAME does not exist"
fi
echo

# Step 3: Clean ECR repository
echo -e "${BLUE}Step 3: Cleaning ECR repository${NC}"
if aws ecr describe-repositories --repository-names "$ECR_REPOSITORY" --region "$REGION" &>/dev/null; then
    echo "Deleting all images in ECR repository..."
    # Delete all images first
    IMAGE_IDS=$(aws ecr list-images --repository-name "$ECR_REPOSITORY" --region "$REGION" --query 'imageIds[*]' --output json)
    if [[ "$IMAGE_IDS" != "[]" ]]; then
        aws ecr batch-delete-image --repository-name "$ECR_REPOSITORY" --region "$REGION" --image-ids "$IMAGE_IDS" || true
    fi
    
    echo "Deleting ECR repository..."
    aws ecr delete-repository --repository-name "$ECR_REPOSITORY" --region "$REGION" --force
    echo "ECR repository deleted successfully"
else
    echo "ECR repository $ECR_REPOSITORY does not exist"
fi
echo

# Step 4: Clean S3 bucket
echo -e "${BLUE}Step 4: Cleaning S3 bucket${NC}"
if aws s3 ls "s3://$S3_BUCKET" &>/dev/null; then
    echo "Emptying S3 bucket..."
    aws s3 rm "s3://$S3_BUCKET" --recursive
    
    echo "Deleting S3 bucket..."
    aws s3 rb "s3://$S3_BUCKET"
    echo "S3 bucket deleted successfully"
else
    echo "S3 bucket $S3_BUCKET does not exist"
fi
echo

# Summary
echo -e "${GREEN}=== Infrastructure Cleanup Complete ===${NC}"
echo -e "${YELLOW}Resources Deleted:${NC}"
echo "✓ EKS Cluster: $CLUSTER_NAME"
echo "✓ ECR Repository: $ECR_REPOSITORY"
echo "✓ S3 Bucket: $S3_BUCKET"
echo "✓ Kubernetes namespace and resources"
echo
echo -e "${GREEN}All AWS resources have been cleaned up!${NC}"