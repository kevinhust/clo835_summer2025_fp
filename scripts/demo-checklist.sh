#!/bin/bash

# CLO835 Final Project - Demo Checklist Script
# This script helps verify all demo requirements are ready

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${GREEN}================================${NC}"
echo -e "${GREEN} CLO835 Final Project Demo Check${NC}"
echo -e "${GREEN}================================${NC}"
echo

# Configuration
NAMESPACE=${NAMESPACE:-"fp"}
S3_BUCKET=${S3_BUCKET_NAME:-"clo835fp-bg-images"}
ECR_REPOSITORY=${ECR_REPOSITORY:-"clo835fp-webapp"}
CLUSTER_NAME=${CLUSTER_NAME:-"clo835-eks-cluster"}
REGION=${AWS_REGION:-"us-east-1"}

echo -e "${BLUE}Demo Requirements Check:${NC}"
echo

# 1. Local Docker functionality
echo -e "${CYAN}1. Local Docker Image Verification${NC}"
if docker images | grep -q webapp; then
    echo "   ✅ Local webapp Docker image exists"
    echo "   🎬 Demo: Run 'docker run -p 8080:81 webapp:latest' and test locally"
else
    echo "   ❌ Local webapp Docker image not found"
    echo "   🔧 Build with: docker build -t webapp:latest ."
fi
echo

# 2. GitHub Actions and ECR
echo -e "${CYAN}2. GitHub Actions & ECR Integration${NC}"
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text 2>/dev/null || echo "unknown")
ECR_URI="$AWS_ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPOSITORY"

if aws ecr describe-repositories --repository-names "$ECR_REPOSITORY" --region "$REGION" &>/dev/null; then
    echo "   ✅ ECR repository exists: $ECR_REPOSITORY"
    
    # Check for images
    IMAGE_COUNT=$(aws ecr list-images --repository-name "$ECR_REPOSITORY" --region "$REGION" --query 'length(imageIds)' --output text 2>/dev/null || echo "0")
    if [ "$IMAGE_COUNT" -gt 0 ]; then
        echo "   ✅ ECR contains $IMAGE_COUNT image(s)"
        echo "   🎬 Demo: Show GitHub Actions workflow and ECR repository"
    else
        echo "   ❌ ECR repository is empty"
        echo "   🔧 Push code to trigger GitHub Actions build"
    fi
else
    echo "   ❌ ECR repository not found"
    echo "   🔧 Run: ./scripts/create-infrastructure.sh"
fi
echo

# 3. EKS Deployment
echo -e "${CYAN}3. EKS Deployment to 'fp' Namespace${NC}"
if kubectl get namespace "$NAMESPACE" &>/dev/null; then
    echo "   ✅ Namespace '$NAMESPACE' exists"
    
    # Check deployments
    if kubectl get deployment webapp-deployment -n "$NAMESPACE" &>/dev/null; then
        echo "   ✅ webapp-deployment exists"
        READY=$(kubectl get deployment webapp-deployment -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        if [ "$READY" -gt 0 ]; then
            echo "   ✅ webapp-deployment is ready ($READY replicas)"
        else
            echo "   ❌ webapp-deployment not ready"
        fi
    else
        echo "   ❌ webapp-deployment not found"
    fi
    
    if kubectl get deployment mysql-deployment -n "$NAMESPACE" &>/dev/null; then
        echo "   ✅ mysql-deployment exists"
        MYSQL_READY=$(kubectl get deployment mysql-deployment -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || echo "0")
        if [ "$MYSQL_READY" -gt 0 ]; then
            echo "   ✅ mysql-deployment is ready ($MYSQL_READY replicas)"
        else
            echo "   ❌ mysql-deployment not ready"
        fi
    else
        echo "   ❌ mysql-deployment not found"
    fi
    
    echo "   🎬 Demo: Show 'kubectl get all -n fp' and deployment process"
else
    echo "   ❌ Namespace '$NAMESPACE' not found"
    echo "   🔧 Run: kubectl apply -f k8s-manifests/"
fi
echo

# 4. S3 Background Image Loading
echo -e "${CYAN}4. S3 Background Image Integration${NC}"
if aws s3 ls "s3://$S3_BUCKET" &>/dev/null; then
    echo "   ✅ S3 bucket exists: $S3_BUCKET"
    
    if aws s3 ls "s3://$S3_BUCKET/background-images/" | grep -q ".jpg"; then
        echo "   ✅ Background images found in S3"
        echo "   Available images:"
        aws s3 ls "s3://$S3_BUCKET/background-images/" --human-readable | grep ".jpg" | awk '{print "     • " $4}'
    else
        echo "   ❌ No background images found in S3"
    fi
    
    # Check ConfigMap
    if kubectl get configmap webapp-config -n "$NAMESPACE" &>/dev/null; then
        CURRENT_URL=$(kubectl get configmap webapp-config -n "$NAMESPACE" -o jsonpath='{.data.BACKGROUND_IMAGE_URL}' 2>/dev/null)
        echo "   ✅ ConfigMap configured: $CURRENT_URL"
    else
        echo "   ❌ ConfigMap not found"
    fi
    
    echo "   🎬 Demo: Show S3 bucket, ConfigMap, and background image loading in browser"
else
    echo "   ❌ S3 bucket not found"
    echo "   🔧 Run: ./scripts/create-infrastructure.sh"
fi
echo

# 5. Data Persistence (PVC/PV)
echo -e "${CYAN}5. Data Persistence with PVC/PV${NC}"
if kubectl get pvc mysql-pvc -n "$NAMESPACE" &>/dev/null; then
    PVC_STATUS=$(kubectl get pvc mysql-pvc -n "$NAMESPACE" -o jsonpath='{.status.phase}' 2>/dev/null)
    if [ "$PVC_STATUS" = "Bound" ]; then
        echo "   ✅ PVC 'mysql-pvc' is bound"
        
        # Check PV
        PV_NAME=$(kubectl get pvc mysql-pvc -n "$NAMESPACE" -o jsonpath='{.spec.volumeName}' 2>/dev/null)
        if [ ! -z "$PV_NAME" ]; then
            echo "   ✅ PV '$PV_NAME' automatically created"
        fi
    else
        echo "   ❌ PVC not bound (status: $PVC_STATUS)"
    fi
    
    echo "   🎬 Demo: Delete MySQL pod, show it recreates and data persists"
    echo "   🎬 Demo Command: kubectl delete pod -l app=mysql -n fp"
else
    echo "   ❌ PVC 'mysql-pvc' not found"
fi
echo

# 6. Internet Access
echo -e "${CYAN}6. Internet Access via LoadBalancer${NC}"
if kubectl get service webapp-service -n "$NAMESPACE" &>/dev/null; then
    SERVICE_TYPE=$(kubectl get service webapp-service -n "$NAMESPACE" -o jsonpath='{.spec.type}')
    echo "   ✅ Service exists (type: $SERVICE_TYPE)"
    
    if [ "$SERVICE_TYPE" = "LoadBalancer" ]; then
        EXTERNAL_IP=$(kubectl get service webapp-service -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "pending")
        if [ "$EXTERNAL_IP" != "pending" ] && [ ! -z "$EXTERNAL_IP" ]; then
            echo "   ✅ External URL: http://$EXTERNAL_IP"
            echo "   🎬 Demo: Access application from browser using this URL"
        else
            echo "   ⏳ LoadBalancer IP pending (may take 2-3 minutes)"
            echo "   🔧 Check with: kubectl get svc webapp-service -n fp"
        fi
    else
        echo "   ❌ Service is not LoadBalancer type"
    fi
else
    echo "   ❌ webapp-service not found"
fi
echo

# 7. Background Image Change Demo
echo -e "${CYAN}7. Background Image Change Demo${NC}"
if kubectl get configmap webapp-config -n "$NAMESPACE" &>/dev/null; then
    echo "   ✅ ConfigMap ready for background change demo"
    echo "   🎬 Demo: Run './scripts/change-background.sh' to switch backgrounds"
    echo "   🎬 Demo: Show browser refresh with new background image"
    
    echo -e "\n   ${YELLOW}Background change demo steps:${NC}"
    echo "   1. Show current background in browser"
    echo "   2. Run: ./scripts/change-background.sh"
    echo "   3. Select different background (2, 3, or 4)"
    echo "   4. Wait for deployment restart"
    echo "   5. Refresh browser to show new background"
else
    echo "   ❌ ConfigMap not ready"
fi
echo

# Demo Summary
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}         Demo Summary${NC}"
echo -e "${GREEN}================================${NC}"
echo -e "${YELLOW}Recording Tips:${NC}"
echo "• Make a 30-minute video with audio narration"
echo "• Show each requirement step by step"
echo "• Explain what you're doing as you go"
echo "• Test all functionality before recording"
echo
echo -e "${YELLOW}Recommended Demo Flow:${NC}"
echo "1. Show local Docker testing"
echo "2. Demonstrate GitHub Actions pipeline"
echo "3. Show EKS deployment and kubectl commands"
echo "4. Access application via LoadBalancer URL"
echo "5. Show S3 integration and current background"
echo "6. Delete MySQL pod and show data persistence"  
echo "7. Change background image and show in browser"
echo
echo -e "${BLUE}Quick Commands for Demo:${NC}"
echo "kubectl get all -n fp                    # Show all resources"
echo "kubectl logs -f deployment/webapp -n fp  # Show application logs"
echo "kubectl delete pod -l app=mysql -n fp    # Test data persistence"
echo "./scripts/change-background.sh          # Change background demo"
echo
echo -e "${GREEN}Ready for your CLO835 demo! 🎬${NC}"