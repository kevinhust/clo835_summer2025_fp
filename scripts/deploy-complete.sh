#!/bin/bash

# CLO835 Final Project - Complete Deployment Script
# This script deploys the entire application infrastructure and validates deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TERRAFORM_DIR="terraform"
K8S_MANIFESTS_DIR="k8s-manifests"
NAMESPACE="clo835"
AWS_REGION="${AWS_REGION:-us-east-1}"
CLUSTER_NAME="${CLUSTER_NAME:-clo835-final-project}"

# Logging functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✓ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

error() {
    echo -e "${RED}✗ $1${NC}"
}

# Cleanup function for failed deployments
cleanup_on_failure() {
    error "Deployment failed. Starting cleanup..."
    
    # Remove Kubernetes resources if they exist
    if kubectl get namespace $NAMESPACE &> /dev/null; then
        log "Cleaning up Kubernetes resources..."
        kubectl delete namespace $NAMESPACE --ignore-not-found=true --timeout=300s || true
    fi
    
    # Note: Terraform cleanup should be done manually to avoid accidental deletion
    warning "Please manually run 'terraform destroy' in the $TERRAFORM_DIR directory if needed"
    
    exit 1
}

# Set up error handling
trap cleanup_on_failure ERR

# Validate prerequisites
validate_prerequisites() {
    log "Validating prerequisites..."
    
    if [ -f "scripts/validate-prerequisites.sh" ]; then
        if ./scripts/validate-prerequisites.sh; then
            success "Prerequisites validation passed"
        else
            error "Prerequisites validation failed"
            return 1
        fi
    else
        warning "Prerequisites validation script not found, skipping..."
    fi
}

# Deploy Terraform infrastructure
deploy_infrastructure() {
    log "=== Deploying Terraform Infrastructure ==="
    
    cd $TERRAFORM_DIR
    
    # Initialize Terraform
    log "Initializing Terraform..."
    terraform init
    
    # Plan deployment
    log "Creating Terraform plan..."
    terraform plan -out=tfplan
    
    # Apply infrastructure
    log "Applying Terraform infrastructure..."
    terraform apply tfplan
    
    # Get outputs
    log "Getting Terraform outputs..."
    CLUSTER_ENDPOINT=$(terraform output -raw cluster_endpoint 2>/dev/null || echo "")
    CLUSTER_NAME=$(terraform output -raw cluster_name 2>/dev/null || echo "$CLUSTER_NAME")
    ECR_REPOSITORY_URL=$(terraform output -raw ecr_repository_url 2>/dev/null || echo "")
    
    if [ -n "$CLUSTER_ENDPOINT" ]; then
        success "EKS cluster created successfully"
        log "Cluster name: $CLUSTER_NAME"
        log "Cluster endpoint: $CLUSTER_ENDPOINT"
    else
        error "Failed to get cluster information from Terraform outputs"
        return 1
    fi
    
    if [ -n "$ECR_REPOSITORY_URL" ]; then
        success "ECR repository available: $ECR_REPOSITORY_URL"
    else
        warning "ECR repository URL not available from Terraform outputs"
    fi
    
    cd ..
}

# Configure kubectl for EKS
configure_kubectl() {
    log "=== Configuring kubectl for EKS ==="
    
    # Update kubeconfig
    log "Updating kubeconfig for cluster: $CLUSTER_NAME"
    aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME
    
    # Verify connection
    log "Verifying kubectl connection..."
    if kubectl cluster-info &> /dev/null; then
        success "kubectl configured successfully"
        
        # Show cluster information
        log "Cluster information:"
        kubectl cluster-info
        
        # Show worker nodes
        log "Worker nodes:"
        kubectl get nodes -o wide
        
    else
        error "Failed to connect to EKS cluster"
        return 1
    fi
}

# Deploy Kubernetes manifests
deploy_kubernetes() {
    log "=== Deploying Kubernetes Manifests ==="
    
    cd $K8S_MANIFESTS_DIR
    
    # Deploy in specific order to handle dependencies
    local manifests=(
        "namespace.yaml"
        "rbac.yaml"
        "configmap.yaml"
        "secrets.yaml"
        "pvc.yaml"
        "mysql-deployment.yaml"
        "mysql-service.yaml"
        "webapp-deployment.yaml"
        "webapp-service.yaml"
    )
    
    for manifest in "${manifests[@]}"; do
        if [ -f "$manifest" ]; then
            log "Deploying $manifest..."
            kubectl apply -f "$manifest"
            success "Deployed $manifest"
        else
            error "Manifest $manifest not found"
            return 1
        fi
    done
    
    cd ..
}

# Wait for pods to be ready
wait_for_pods() {
    log "=== Waiting for Pods to be Ready ==="
    
    # Wait for MySQL deployment
    log "Waiting for MySQL deployment to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/mysql-deployment -n $NAMESPACE
    success "MySQL deployment is ready"
    
    # Wait for webapp deployment
    log "Waiting for webapp deployment to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/webapp-deployment -n $NAMESPACE
    success "Webapp deployment is ready"
    
    # Wait for all pods to be running
    log "Waiting for all pods to be running..."
    kubectl wait --for=condition=ready --timeout=300s pods --all -n $NAMESPACE
    success "All pods are running"
    
    # Show pod status
    log "Pod status:"
    kubectl get pods -n $NAMESPACE -o wide
}

# Verify services
verify_services() {
    log "=== Verifying Services ==="
    
    # Show all services
    log "Services in namespace $NAMESPACE:"
    kubectl get services -n $NAMESPACE
    
    # Get LoadBalancer URL
    log "Waiting for LoadBalancer to get external IP..."
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        EXTERNAL_IP=$(kubectl get service webapp-service -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")
        
        if [ -n "$EXTERNAL_IP" ] && [ "$EXTERNAL_IP" != "null" ]; then
            success "LoadBalancer external URL: http://$EXTERNAL_IP"
            break
        else
            log "Attempt $attempt/$max_attempts: Waiting for external IP..."
            sleep 10
            ((attempt++))
        fi
    done
    
    if [ -z "$EXTERNAL_IP" ] || [ "$EXTERNAL_IP" = "null" ]; then
        warning "LoadBalancer external IP not available yet. This is normal for new clusters."
        warning "You can check later with: kubectl get service webapp-service -n $NAMESPACE"
    fi
}

# Run post-deployment tests
run_tests() {
    log "=== Running Post-Deployment Tests ==="
    
    if [ -f "scripts/test-functionality.sh" ]; then
        log "Running functionality tests..."
        ./scripts/test-functionality.sh
    else
        warning "Functionality test script not found, skipping tests..."
    fi
}

# Main deployment function
main() {
    log "Starting CLO835 Final Project Complete Deployment..."
    echo
    
    # Record start time
    START_TIME=$(date +%s)
    
    # Validate prerequisites
    validate_prerequisites
    echo
    
    # Deploy infrastructure
    deploy_infrastructure
    echo
    
    # Configure kubectl
    configure_kubectl
    echo
    
    # Deploy Kubernetes manifests
    deploy_kubernetes
    echo
    
    # Wait for pods to be ready
    wait_for_pods
    echo
    
    # Verify services
    verify_services
    echo
    
    # Run tests
    run_tests
    echo
    
    # Calculate deployment time
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    success "Deployment completed successfully!"
    log "Total deployment time: $DURATION seconds"
    
    echo
    log "=== Deployment Summary ==="
    log "Namespace: $NAMESPACE"
    log "Cluster: $CLUSTER_NAME"
    log "Region: $AWS_REGION"
    
    if [ -n "$EXTERNAL_IP" ] && [ "$EXTERNAL_IP" != "null" ]; then
        log "Application URL: http://$EXTERNAL_IP"
    else
        log "Application URL: Check LoadBalancer service for external IP"
    fi
    
    echo
    log "Next steps:"
    log "1. Access the application via the LoadBalancer URL"
    log "2. Test the application functionality"
    log "3. Update ConfigMap to test background image changes"
    log "4. Run: kubectl get all -n $NAMESPACE  # to see all resources"
    echo
    
    log "To cleanup resources, run:"
    log "1. kubectl delete namespace $NAMESPACE"
    log "2. cd $TERRAFORM_DIR && terraform destroy"
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "CLO835 Final Project - Complete Deployment Script"
        echo
        echo "Usage: $0 [options]"
        echo
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --skip-tests   Skip post-deployment tests"
        echo
        echo "Environment Variables:"
        echo "  AWS_REGION     AWS region (default: us-east-1)"
        echo "  CLUSTER_NAME   EKS cluster name (default: clo835-final-project)"
        echo
        exit 0
        ;;
    --skip-tests)
        log "Skipping post-deployment tests as requested"
        run_tests() { log "Tests skipped"; }
        ;;
esac

# Run main deployment
main