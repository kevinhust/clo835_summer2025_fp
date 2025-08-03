#!/bin/bash

# CLO835 Final Project - Prerequisites Validation Script
# This script validates all required tools and configurations before deployment

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
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

# Check if command exists
check_command() {
    if command -v "$1" &> /dev/null; then
        success "$1 is installed"
        return 0
    else
        error "$1 is not installed"
        return 1
    fi
}

# Check version of command
check_version() {
    local cmd=$1
    local version_flag=$2
    local min_version=$3
    
    if command -v "$cmd" &> /dev/null; then
        local current_version=$($cmd $version_flag 2>&1 | head -n1)
        success "$cmd is installed: $current_version"
        if [ -n "$min_version" ]; then
            log "Minimum required version: $min_version"
        fi
    else
        error "$cmd is not installed"
        return 1
    fi
}

log "Starting CLO835 Final Project Prerequisites Validation..."
echo

# Track validation results
VALIDATION_FAILED=0

log "=== Checking Required Tools ==="

# Check Docker
if check_command "docker"; then
    docker_version=$(docker --version)
    success "Docker version: $docker_version"
    
    # Check if Docker daemon is running
    if docker info &> /dev/null; then
        success "Docker daemon is running"
    else
        error "Docker daemon is not running. Please start Docker."
        VALIDATION_FAILED=1
    fi
else
    error "Docker is required for local testing"
    VALIDATION_FAILED=1
fi

# Check AWS CLI
if check_command "aws"; then
    aws_version=$(aws --version 2>&1)
    success "AWS CLI version: $aws_version"
else
    error "AWS CLI is required for EKS and ECR operations"
    VALIDATION_FAILED=1
fi

# Check kubectl
if check_command "kubectl"; then
    kubectl_version=$(kubectl version --client --short 2>/dev/null || kubectl version --client 2>/dev/null)
    success "kubectl version: $kubectl_version"
else
    error "kubectl is required for Kubernetes operations"
    VALIDATION_FAILED=1
fi

# Check Terraform
if check_command "terraform"; then
    terraform_version=$(terraform version | head -n1)
    success "Terraform version: $terraform_version"
else
    error "Terraform is required for infrastructure provisioning"
    VALIDATION_FAILED=1
fi

# Check eksctl
if check_command "eksctl"; then
    eksctl_version=$(eksctl version)
    success "eksctl version: $eksctl_version"
else
    warning "eksctl is recommended for EKS cluster management"
fi

# Check Git
if check_command "git"; then
    git_version=$(git --version)
    success "Git version: $git_version"
else
    error "Git is required for source code management"
    VALIDATION_FAILED=1
fi

echo
log "=== Checking AWS Configuration ==="

# Check AWS credentials
if aws sts get-caller-identity &> /dev/null; then
    aws_identity=$(aws sts get-caller-identity --query 'Account' --output text 2>/dev/null)
    aws_region=$(aws configure get region 2>/dev/null || echo "Not set")
    success "AWS credentials are configured"
    log "AWS Account ID: $aws_identity"
    log "AWS Region: $aws_region"
    
    if [ "$aws_region" = "Not set" ]; then
        warning "AWS region is not set. Please run: aws configure set region us-east-1"
    fi
else
    error "AWS credentials are not configured or invalid"
    error "Please run: aws configure"
    VALIDATION_FAILED=1
fi

# Check ECR access
if aws ecr describe-repositories --region us-east-1 &> /dev/null; then
    success "ECR access is working"
else
    warning "ECR access check failed. This might be due to no repositories existing yet."
fi

# Check EKS access
if aws eks list-clusters --region us-east-1 &> /dev/null; then
    success "EKS access is working"
    
    # List existing clusters
    clusters=$(aws eks list-clusters --region us-east-1 --query 'clusters' --output text 2>/dev/null)
    if [ -n "$clusters" ] && [ "$clusters" != "None" ]; then
        log "Existing EKS clusters: $clusters"
    else
        log "No existing EKS clusters found"
    fi
else
    error "EKS access check failed. Please verify IAM permissions."
    VALIDATION_FAILED=1
fi

# Check S3 access
if aws s3 ls &> /dev/null; then
    success "S3 access is working"
else
    error "S3 access check failed. Please verify IAM permissions."
    VALIDATION_FAILED=1
fi

echo
log "=== Checking GitHub Configuration ==="

# Check if we're in a git repository
if git rev-parse --is-inside-work-tree &> /dev/null; then
    success "Current directory is a Git repository"
    
    # Check remote origin
    if git remote get-url origin &> /dev/null; then
        remote_url=$(git remote get-url origin)
        success "Git remote origin: $remote_url"
        
        if [[ "$remote_url" == *"github.com"* ]]; then
            success "Repository is hosted on GitHub"
        else
            warning "Repository is not hosted on GitHub"
        fi
    else
        warning "No Git remote origin configured"
    fi
    
    # Check current branch
    current_branch=$(git branch --show-current 2>/dev/null || echo "unknown")
    log "Current branch: $current_branch"
    
    # Check for uncommitted changes
    if git diff-index --quiet HEAD -- 2>/dev/null; then
        success "Working directory is clean"
    else
        warning "There are uncommitted changes in the working directory"
    fi
    
else
    error "Current directory is not a Git repository"
    VALIDATION_FAILED=1
fi

echo
log "=== Checking Project Structure ==="

# Check required files and directories
required_files=(
    "app.py"
    "Dockerfile" 
    "requirements.txt"
    "k8s-manifests/"
    "terraform/"
    ".github/workflows/"
)

for item in "${required_files[@]}"; do
    if [ -e "$item" ]; then
        success "Found: $item"
    else
        error "Missing: $item"
        VALIDATION_FAILED=1
    fi
done

# Check Kubernetes manifests
k8s_manifests=(
    "k8s-manifests/namespace.yaml"
    "k8s-manifests/configmap.yaml"
    "k8s-manifests/secrets.yaml"
    "k8s-manifests/pvc.yaml"
    "k8s-manifests/mysql-deployment.yaml"
    "k8s-manifests/mysql-service.yaml"
    "k8s-manifests/webapp-deployment.yaml"
    "k8s-manifests/webapp-service.yaml"
    "k8s-manifests/rbac.yaml"
)

log "Checking Kubernetes manifests..."
for manifest in "${k8s_manifests[@]}"; do
    if [ -f "$manifest" ]; then
        success "Found: $manifest"
    else
        error "Missing: $manifest"
        VALIDATION_FAILED=1
    fi
done

# Check GitHub Actions workflows
gh_workflows=(
    ".github/workflows/ci-cd.yml"
)

log "Checking GitHub Actions workflows..."
for workflow in "${gh_workflows[@]}"; do
    if [ -f "$workflow" ]; then
        success "Found: $workflow"
    else
        error "Missing: $workflow"
        VALIDATION_FAILED=1
    fi
done

# Check Terraform files
terraform_files=(
    "terraform/main.tf"
    "terraform/variables.tf"
    "terraform/outputs.tf"
    "terraform/versions.tf"
)

log "Checking Terraform files..."
for tf_file in "${terraform_files[@]}"; do
    if [ -f "$tf_file" ]; then
        success "Found: $tf_file"
    else
        error "Missing: $tf_file"
        VALIDATION_FAILED=1
    fi
done

echo
log "=== Environment Variables Check ==="

# Check for required environment variables
env_vars=(
    "AWS_ACCESS_KEY_ID:Optional for local development"
    "AWS_SECRET_ACCESS_KEY:Optional for local development"
    "AWS_REGION:Recommended to be set"
)

for var_info in "${env_vars[@]}"; do
    var_name="${var_info%%:*}"
    var_desc="${var_info##*:}"
    
    if [ -n "${!var_name}" ]; then
        success "$var_name is set"
    else
        warning "$var_name is not set ($var_desc)"
    fi
done

echo
log "=== Validation Summary ==="

if [ $VALIDATION_FAILED -eq 0 ]; then
    success "All prerequisites validation checks passed!"
    echo
    log "You are ready to proceed with the CLO835 Final Project deployment."
    log "Next steps:"
    log "1. Run: ./scripts/deploy-complete.sh"
    log "2. Or deploy individual components manually"
    echo
    exit 0
else
    error "Some prerequisites validation checks failed!"
    echo
    log "Please address the issues above before proceeding with deployment."
    log "Common solutions:"
    log "- Install missing tools using package managers (brew, apt, yum, etc.)"
    log "- Configure AWS credentials: aws configure"
    log "- Ensure Docker daemon is running"
    log "- Set up GitHub repository with required files"
    echo
    exit 1
fi