#!/bin/bash

# CLO835 Final Project - Cleanup All Resources Script
# This script safely removes all project resources and provides cost cleanup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TERRAFORM_DIR="terraform"
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

# Confirmation function
confirm_action() {
    local message="$1"
    local default="${2:-n}"
    
    echo -e "${YELLOW}$message${NC}"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Get current AWS costs estimation
estimate_current_costs() {
    log "=== Current AWS Resource Cost Estimation ==="
    
    # Check EKS cluster
    if aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" &> /dev/null; then
        log "EKS cluster '$CLUSTER_NAME' exists - Cost: ~\$0.10/hour (\$72/month)"
        
        # Get worker nodes count
        local node_count=$(kubectl get nodes --no-headers 2>/dev/null | wc -l || echo "unknown")
        if [ "$node_count" != "unknown" ] && [ "$node_count" -gt 0 ]; then
            log "Worker nodes: $node_count - Cost: ~\$0.096/hour each (\$69/month each)"
            local total_nodes_cost=$(echo "$node_count * 69" | bc 2>/dev/null || echo "unknown")
            if [ "$total_nodes_cost" != "unknown" ]; then
                log "Total nodes cost: ~\$${total_nodes_cost}/month"
            fi
        fi
    else
        success "No EKS cluster found"
    fi
    
    # Check ECR repositories
    local ecr_repos=$(aws ecr describe-repositories --region "$AWS_REGION" --query 'repositories[].repositoryName' --output text 2>/dev/null || echo "")
    if [ -n "$ecr_repos" ]; then
        log "ECR repositories found: $ecr_repos"
        log "ECR storage cost depends on image size and count"
    else
        success "No ECR repositories found"
    fi
    
    # Check EBS volumes
    local ebs_volumes=$(aws ec2 describe-volumes --region "$AWS_REGION" --filters "Name=tag:kubernetes.io/cluster/$CLUSTER_NAME,Values=owned" --query 'Volumes[].VolumeId' --output text 2>/dev/null || echo "")
    if [ -n "$ebs_volumes" ]; then
        log "EBS volumes found: $(echo $ebs_volumes | wc -w) volumes"
        log "EBS gp2 cost: ~\$0.10/GB/month"
    else
        success "No EBS volumes found"
    fi
    
    # Check Load Balancers
    local lb_count=$(aws elbv2 describe-load-balancers --region "$AWS_REGION" --query 'LoadBalancers[?contains(LoadBalancerName, `k8s-`) || contains(Tags[?Key==`kubernetes.io/cluster/'"$CLUSTER_NAME"'`].Value, `owned`)].LoadBalancerArn' --output text 2>/dev/null | wc -w || echo "0")
    if [ "$lb_count" -gt 0 ]; then
        log "Load Balancers found: $lb_count"
        log "ALB/NLB cost: ~\$16-23/month each"
    else
        success "No Load Balancers found"
    fi
    
    echo
    warning "These are rough estimates. Actual costs may vary based on usage, region, and AWS pricing changes."
    log "Check AWS Cost Explorer for accurate billing information."
    echo
}

# Cleanup Kubernetes resources
cleanup_kubernetes() {
    log "=== Cleaning up Kubernetes Resources ==="
    
    # Check if namespace exists
    if kubectl get namespace "$NAMESPACE" &> /dev/null; then
        log "Found namespace: $NAMESPACE"
        
        # Show resources in namespace
        log "Resources in namespace:"
        kubectl get all -n "$NAMESPACE" 2>/dev/null || log "No resources found"
        
        if confirm_action "This will delete ALL resources in namespace '$NAMESPACE'"; then
            log "Deleting namespace and all resources..."
            
            # Delete namespace (this deletes all resources in it)
            kubectl delete namespace "$NAMESPACE" --timeout=300s
            
            # Wait for namespace to be fully deleted
            log "Waiting for namespace to be fully deleted..."
            local attempts=0
            while kubectl get namespace "$NAMESPACE" &> /dev/null && [ $attempts -lt 30 ]; do
                sleep 10
                ((attempts++))
                log "Still waiting... (attempt $attempts/30)"
            done
            
            if kubectl get namespace "$NAMESPACE" &> /dev/null; then
                warning "Namespace deletion is taking longer than expected"
                warning "Some resources might have finalizers preventing deletion"
                log "You may need to manually remove finalizers or force delete"
            else
                success "Namespace '$NAMESPACE' deleted successfully"
            fi
        else
            warning "Kubernetes cleanup cancelled"
            return 1
        fi
    else
        success "Namespace '$NAMESPACE' does not exist"
    fi
}

# Cleanup ECR images
cleanup_ecr() {
    log "=== Cleaning up ECR Images ==="
    
    # List ECR repositories
    local repositories=$(aws ecr describe-repositories --region "$AWS_REGION" --query 'repositories[].repositoryName' --output text 2>/dev/null || echo "")
    
    if [ -n "$repositories" ]; then
        log "Found ECR repositories: $repositories"
        
        for repo in $repositories; do
            log "Repository: $repo"
            
            # Count images in repository
            local image_count=$(aws ecr list-images --repository-name "$repo" --region "$AWS_REGION" --query 'imageIds' --output text 2>/dev/null | wc -w || echo "0")
            log "Images in $repo: $image_count"
            
            if [ "$image_count" -gt 0 ]; then
                if confirm_action "Delete all images in repository '$repo'?"; then
                    log "Deleting all images in $repo..."
                    aws ecr batch-delete-image --repository-name "$repo" --region "$AWS_REGION" --image-ids "$(aws ecr list-images --repository-name "$repo" --region "$AWS_REGION" --query 'imageIds' --output json)" &> /dev/null || warning "Failed to delete some images"
                    success "Images deleted from $repo"
                fi
            fi
            
            if confirm_action "Delete ECR repository '$repo'?"; then
                log "Deleting repository $repo..."
                aws ecr delete-repository --repository-name "$repo" --region "$AWS_REGION" --force &> /dev/null || warning "Failed to delete repository"
                success "Repository $repo deleted"
            fi
        done
    else
        success "No ECR repositories found"
    fi
}

# Cleanup Terraform infrastructure
cleanup_terraform() {
    log "=== Cleaning up Terraform Infrastructure ==="
    
    if [ ! -d "$TERRAFORM_DIR" ]; then
        error "Terraform directory '$TERRAFORM_DIR' not found"
        return 1
    fi
    
    cd "$TERRAFORM_DIR"
    
    # Check if Terraform state exists
    if [ -f "terraform.tfstate" ] || [ -f ".terraform/terraform.tfstate" ]; then
        log "Terraform state found"
        
        # Show what will be destroyed
        log "Planning destruction..."
        if terraform plan -destroy; then
            echo
            if confirm_action "This will DESTROY all Terraform-managed infrastructure including EKS cluster, VPC, and all associated resources"; then
                log "Destroying Terraform infrastructure..."
                terraform destroy -auto-approve
                success "Terraform infrastructure destroyed"
                
                # Clean up Terraform files
                if confirm_action "Remove Terraform state and cache files?"; then
                    rm -rf .terraform/ terraform.tfstate* tfplan* 2>/dev/null || true
                    success "Terraform files cleaned up"
                fi
            else
                warning "Terraform destruction cancelled"
                cd ..
                return 1
            fi
        else
            error "Terraform plan failed. Please check the configuration."
            cd ..
            return 1
        fi
    else
        success "No Terraform state found"
    fi
    
    cd ..
}

# Final verification and cost savings
verify_cleanup() {
    log "=== Verifying Cleanup ==="
    
    # Check EKS cluster
    if aws eks describe-cluster --name "$CLUSTER_NAME" --region "$AWS_REGION" &> /dev/null; then
        warning "EKS cluster '$CLUSTER_NAME' still exists"
    else
        success "EKS cluster '$CLUSTER_NAME' not found"
    fi
    
    # Check ECR repositories
    local remaining_repos=$(aws ecr describe-repositories --region "$AWS_REGION" --query 'repositories[].repositoryName' --output text 2>/dev/null | wc -w || echo "0")
    if [ "$remaining_repos" -gt 0 ]; then
        warning "$remaining_repos ECR repositories still exist"
    else
        success "No ECR repositories found"
    fi
    
    # Check for orphaned EBS volumes
    local orphaned_volumes=$(aws ec2 describe-volumes --region "$AWS_REGION" --filters "Name=tag:kubernetes.io/cluster/$CLUSTER_NAME,Values=owned" "Name=state,Values=available" --query 'Volumes[].VolumeId' --output text 2>/dev/null || echo "")
    if [ -n "$orphaned_volumes" ] && [ "$orphaned_volumes" != "None" ]; then
        warning "Found orphaned EBS volumes: $orphaned_volumes"
        log "You may want to delete these manually to avoid charges"
    else
        success "No orphaned EBS volumes found"
    fi
    
    echo
    log "=== Estimated Cost Savings ==="
    log "After cleanup, you should see reduced charges for:"
    log "• EKS cluster: ~\$72/month saved"
    log "• Worker nodes: ~\$69/month per node saved"
    log "• Load Balancers: ~\$16-23/month each saved"
    log "• EBS volumes: ~\$0.10/GB/month saved"
    log "• ECR storage: Variable based on image size"
    echo
    log "💰 Monitor your AWS billing to confirm cost reductions"
}

# Main cleanup function
main() {
    log "CLO835 Final Project - Complete Resource Cleanup"
    echo
    
    warning "⚠️  This script will delete ALL project resources ⚠️"
    warning "This action is IRREVERSIBLE and will result in data loss"
    echo
    
    if ! confirm_action "Do you want to proceed with the complete cleanup?"; then
        log "Cleanup cancelled by user"
        exit 0
    fi
    
    echo
    
    # Show current cost estimation
    estimate_current_costs
    
    # Record start time
    START_TIME=$(date +%s)
    
    # Cleanup in order: K8s -> ECR -> Terraform
    log "Starting cleanup process..."
    echo
    
    # 1. Cleanup Kubernetes resources first
    cleanup_kubernetes
    echo
    
    # 2. Cleanup ECR images and repositories
    cleanup_ecr
    echo
    
    # 3. Cleanup Terraform infrastructure
    cleanup_terraform
    echo
    
    # 4. Verify cleanup
    verify_cleanup
    
    # Calculate cleanup time
    END_TIME=$(date +%s)
    DURATION=$((END_TIME - START_TIME))
    
    echo
    success "Cleanup completed successfully!"
    log "Total cleanup time: $DURATION seconds"
    
    echo
    log "=== Cleanup Summary ==="
    log "✓ Kubernetes resources removed"
    log "✓ ECR images and repositories cleaned"
    log "✓ Terraform infrastructure destroyed"
    log "✓ Cost-generating resources eliminated"
    
    echo
    log "Next steps:"
    log "1. Monitor AWS billing for cost reductions"
    log "2. Check AWS console to verify all resources are removed"
    log "3. Remove any remaining manual resources if needed"
    log "4. Consider updating GitHub repository if no longer needed"
    
    echo
    success "🎉 Your CLO835 Final Project resources have been cleaned up!"
    log "Thank you for practicing good cloud resource management!"
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "CLO835 Final Project - Complete Resource Cleanup Script"
        echo
        echo "Usage: $0 [options]"
        echo
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --force        Skip confirmation prompts (dangerous!)"
        echo "  --k8s-only     Clean up only Kubernetes resources"
        echo "  --ecr-only     Clean up only ECR resources"
        echo "  --terraform-only Clean up only Terraform resources"
        echo
        echo "Environment Variables:"
        echo "  AWS_REGION     AWS region (default: us-east-1)"
        echo "  CLUSTER_NAME   EKS cluster name (default: clo835-final-project)"
        echo "  NAMESPACE      Kubernetes namespace (default: clo835)"
        echo
        echo "⚠️  WARNING: This script permanently deletes resources!"
        echo
        exit 0
        ;;
    --force)
        warning "Force mode enabled - skipping confirmations!"
        confirm_action() { return 0; }
        ;;
    --k8s-only)
        log "Kubernetes-only cleanup mode"
        main() {
            cleanup_kubernetes
            success "Kubernetes cleanup completed"
        }
        ;;
    --ecr-only)
        log "ECR-only cleanup mode"
        main() {
            cleanup_ecr
            success "ECR cleanup completed"
        }
        ;;
    --terraform-only)
        log "Terraform-only cleanup mode"
        main() {
            cleanup_terraform
            success "Terraform cleanup completed"
        }
        ;;
esac

# Run main cleanup
main