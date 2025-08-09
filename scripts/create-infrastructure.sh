#!/bin/bash

# CLO835 Final Project - Infrastructure Setup Script
# This script creates all required AWS resources using CLI commands

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}CLO835 Final Project - Infrastructure Setup${NC}"
echo "This script will create:"
echo "1. S3 bucket for background images"
echo "2. ECR repository for Docker images"  
echo "3. EKS cluster using eksctl"
echo

# Configuration
REGION=${AWS_REGION:-"us-east-1"}
S3_BUCKET=${S3_BUCKET_NAME:-"clo835fp-bg-images"}
ECR_REPOSITORY=${ECR_REPOSITORY:-"clo835fp-webapp"}
CLUSTER_NAME=${CLUSTER_NAME:-"clo835-eks-cluster"}

echo -e "${YELLOW}Configuration:${NC}"
echo "Region: $REGION"
echo "S3 Bucket: $S3_BUCKET"
echo "ECR Repository: $ECR_REPOSITORY"
echo "EKS Cluster: $CLUSTER_NAME"
echo

# Check if aws CLI is configured
echo -e "${BLUE}Step 1: Checking AWS CLI configuration${NC}"
if ! aws sts get-caller-identity &>/dev/null; then
    echo -e "${RED}Error: AWS CLI not configured. Please run 'aws configure'${NC}"
    exit 1
fi

AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "AWS Account ID: $AWS_ACCOUNT_ID"
echo

# Step 1: Verify S3 bucket for background images
echo -e "${BLUE}Step 2: Verifying S3 bucket for background images${NC}"
if aws s3 ls "s3://$S3_BUCKET" &>/dev/null; then
    echo "✓ S3 bucket $S3_BUCKET already exists"
    
    # Check if background-images folder exists
    if aws s3 ls "s3://$S3_BUCKET/background-images/" &>/dev/null; then
        echo "✓ background-images/ folder found"
        echo "Available background images:"
        aws s3 ls "s3://$S3_BUCKET/background-images/" --human-readable
    else
        echo "! background-images/ folder not found, creating it..."
        # Create a placeholder file to create the folder structure
        echo "placeholder" | aws s3 cp - "s3://$S3_BUCKET/background-images/.placeholder"
    fi
else
    echo "Creating S3 bucket $S3_BUCKET..."
    if [ "$REGION" = "us-east-1" ]; then
        aws s3 mb "s3://$S3_BUCKET" --region "$REGION"
    else
        aws s3 mb "s3://$S3_BUCKET" --region "$REGION" --create-bucket-configuration LocationConstraint="$REGION"
    fi
    echo "S3 bucket $S3_BUCKET created successfully"
    
    # Create folder structure
    echo "Creating folder structure..."
    echo "placeholder" | aws s3 cp - "s3://$S3_BUCKET/background-images/.placeholder"
fi

# Ensure bucket is private (security best practice)
echo "Ensuring S3 bucket is private..."
aws s3api put-public-access-block \
    --bucket "$S3_BUCKET" \
    --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" 2>/dev/null || echo "Note: Public access block may already be configured"
echo

# Step 2: Create ECR repository
echo -e "${BLUE}Step 3: Creating ECR repository${NC}"
if aws ecr describe-repositories --repository-names "$ECR_REPOSITORY" --region "$REGION" &>/dev/null; then
    echo "ECR repository $ECR_REPOSITORY already exists"
else
    aws ecr create-repository --repository-name "$ECR_REPOSITORY" --region "$REGION" --image-scanning-configuration scanOnPush=true
    echo "ECR repository $ECR_REPOSITORY created successfully"
fi

ECR_URI="$AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPOSITORY"
echo "ECR URI: $ECR_URI"
echo

# Step 3: Create EKS cluster using eksctl
echo -e "${BLUE}Step 4: Creating EKS cluster using eksctl${NC}"
echo "This may take 15-20 minutes..."

if eksctl get cluster --name "$CLUSTER_NAME" --region "$REGION" &>/dev/null; then
    echo "EKS cluster $CLUSTER_NAME already exists"
else
    eksctl create cluster -f eks-cluster.yaml
    echo "EKS cluster $CLUSTER_NAME created successfully"
fi

# Update kubeconfig
echo "Updating kubeconfig..."
aws eks update-kubeconfig --region "$REGION" --name "$CLUSTER_NAME"
echo

# Step 4: Create namespace
echo -e "${BLUE}Step 5: Creating Kubernetes namespace${NC}"
kubectl create namespace fp --dry-run=client -o yaml | kubectl apply -f -
echo "Namespace 'fp' created/updated"
echo

# Step 5: Verify cluster status
echo -e "${BLUE}Step 6: Verifying cluster status${NC}"
kubectl get nodes
echo
kubectl get namespaces
echo

# Summary
echo -e "${GREEN}=== Infrastructure Setup Complete ===${NC}"
echo -e "${YELLOW}Resources Created:${NC}"
echo "✓ S3 Bucket: s3://$S3_BUCKET"
echo "✓ ECR Repository: $ECR_URI"
echo "✓ EKS Cluster: $CLUSTER_NAME (2 worker nodes)"
echo "✓ Kubernetes Namespace: fp"
echo
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Upload background images to S3 bucket"
echo "2. Set GitHub Secrets for AWS credentials"
echo "3. Deploy application using: kubectl apply -f k8s-manifests/"
echo "4. Or push code to trigger GitHub Actions deployment"
echo

# Background image status
echo -e "${BLUE}Background image status${NC}"
if aws s3 ls "s3://$S3_BUCKET/background-images/" --recursive | grep -v "\.placeholder" | grep -q "."; then
    echo "✓ Background images found in bucket:"
    aws s3 ls "s3://$S3_BUCKET/background-images/" --recursive --human-readable | grep -v ".placeholder"
    echo
    echo -e "${GREEN}Available background images for demo:${NC}"
    echo "  • default-bg.jpg (currently active)"
    echo "  • blue-theme.jpg"
    echo "  • green-theme.jpg"
    echo "  • professional-bg.jpg"
    echo
    echo -e "${YELLOW}Demo tip:${NC} Use './scripts/change-background.sh' to quickly switch backgrounds"
else
    echo "! No background images found in s3://$S3_BUCKET/background-images/"
    echo "  Please upload background images manually to the S3 bucket."
fi

echo
echo -e "${GREEN}Setup completed successfully!${NC}"