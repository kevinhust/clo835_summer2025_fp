#!/bin/bash

# CLO835 Final Project Deployment Script
# This script automates the deployment process based on lessons learned

set -e

echo "🚀 Starting CLO835 Final Project Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
CLUSTER_NAME="clo835-eks-cluster"
NAMESPACE="fp"
ECR_REPO="clo835fp-webapp"
REGION="us-east-1"

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check AWS CLI
    if ! command -v aws &> /dev/null; then
        log_error "AWS CLI is not installed"
        exit 1
    fi
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        log_error "kubectl is not installed"
        exit 1
    fi
    
    # Check terraform
    if ! command -v terraform &> /dev/null; then
        log_error "terraform is not installed"
        exit 1
    fi
    
    log_info "All prerequisites met ✓"
}

deploy_infrastructure() {
    log_info "Deploying infrastructure with Terraform..."
    
    cd terraform
    
    # Initialize Terraform
    terraform init
    
    # Plan deployment
    terraform plan -out=tfplan
    
    # Apply deployment
    terraform apply tfplan
    
    cd ..
    
    log_info "Infrastructure deployed ✓"
}

setup_kubeconfig() {
    log_info "Setting up kubectl configuration..."
    
    aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME
    
    # Verify connection
    kubectl cluster-info
    
    log_info "kubectl configured ✓"
}

wait_for_ebs_csi() {
    log_info "Waiting for EBS CSI driver to be ready..."
    
    # Wait for EBS CSI addon to be active
    while true; do
        STATUS=$(aws eks describe-addon --cluster-name $CLUSTER_NAME --addon-name aws-ebs-csi-driver --region $REGION --query 'addon.status' --output text 2>/dev/null || echo "NOT_FOUND")
        if [ "$STATUS" = "ACTIVE" ]; then
            log_info "EBS CSI driver is active ✓"
            break
        elif [ "$STATUS" = "NOT_FOUND" ]; then
            log_warn "EBS CSI driver not found, waiting..."
        else
            log_warn "EBS CSI driver status: $STATUS, waiting..."
        fi
        sleep 10
    done
    
    # Wait for EBS CSI pods to be ready
    kubectl wait --for=condition=ready pod -l app=ebs-csi-controller -n kube-system --timeout=300s
    
    log_info "EBS CSI driver ready ✓"
}

update_manifests() {
    log_info "Updating Kubernetes manifests..."
    
    # Get AWS Account ID
    AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    ECR_URL="${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/${ECR_REPO}"
    IAM_ROLE_ARN="arn:aws:iam::${AWS_ACCOUNT_ID}:role/LabRole"
    
    # Update webapp deployment
    sed -i.bak "s|\${ECR_REPOSITORY_URI}|${ECR_URL}|g" k8s-manifests/webapp-deployment.yaml
    
    # Update service account
    sed -i.bak "s|\${IAM_ROLE_ARN}|${IAM_ROLE_ARN}|g" k8s-manifests/rbac.yaml
    
    log_info "Manifests updated ✓"
    log_info "ECR URL: ${ECR_URL}"
    log_info "IAM Role ARN: ${IAM_ROLE_ARN}"
}

deploy_application() {
    log_info "Deploying application to Kubernetes..."
    
    # Apply manifests
    kubectl apply -f k8s-manifests/
    
    # Wait for MySQL to be ready
    log_info "Waiting for MySQL to be ready..."
    kubectl wait --for=condition=ready pod -l app=mysql -n $NAMESPACE --timeout=300s
    
    # Wait for webapp to be ready
    log_info "Waiting for webapp to be ready..."
    kubectl wait --for=condition=ready pod -l app=webapp -n $NAMESPACE --timeout=300s
    
    log_info "Application deployed ✓"
}

verify_deployment() {
    log_info "Verifying deployment..."
    
    # Check pods status
    kubectl get pods -n $NAMESPACE
    
    # Check services
    kubectl get svc -n $NAMESPACE
    
    # Get application URL
    URL=$(kubectl get svc webapp-service -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
    
    if [ -n "$URL" ]; then
        log_info "Application URL: http://${URL}"
        
        # Test application
        log_info "Testing application..."
        if curl -s "http://${URL}" | grep -q "background-image"; then
            log_info "Application is responding correctly ✓"
        else
            log_warn "Application may not be fully ready yet"
        fi
    else
        log_warn "LoadBalancer URL not yet available"
    fi
}

cleanup_manifests() {
    log_info "Cleaning up temporary manifest files..."
    
    # Restore original manifests
    if [ -f k8s-manifests/webapp-deployment.yaml.bak ]; then
        mv k8s-manifests/webapp-deployment.yaml.bak k8s-manifests/webapp-deployment.yaml
    fi
    
    if [ -f k8s-manifests/rbac.yaml.bak ]; then
        mv k8s-manifests/rbac.yaml.bak k8s-manifests/rbac.yaml
    fi
    
    log_info "Cleanup completed ✓"
}

# Main deployment flow
main() {
    echo "=================================="
    echo "CLO835 Final Project Deployment"
    echo "=================================="
    
    check_prerequisites
    
    case "${1:-all}" in
        "infra")
            deploy_infrastructure
            ;;
        "app")
            setup_kubeconfig
            wait_for_ebs_csi
            update_manifests
            deploy_application
            verify_deployment
            cleanup_manifests
            ;;
        "all")
            deploy_infrastructure
            setup_kubeconfig
            wait_for_ebs_csi
            update_manifests
            deploy_application
            verify_deployment
            cleanup_manifests
            ;;
        "verify")
            setup_kubeconfig
            verify_deployment
            ;;
        *)
            echo "Usage: $0 [infra|app|all|verify]"
            echo "  infra  - Deploy infrastructure only"
            echo "  app    - Deploy application only"
            echo "  all    - Deploy infrastructure and application (default)"
            echo "  verify - Verify deployment status"
            exit 1
            ;;
    esac
    
    log_info "Deployment completed successfully! 🎉"
}

# Trap to ensure cleanup on exit
trap cleanup_manifests EXIT

# Run main function
main "$@"
