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
ECR_REPOSITORY=${ECR_REPOSITORY:-"clo835fp-webapp"}
CLUSTER_NAME=${CLUSTER_NAME:-"clo835-eks-cluster"}
PROJECT_TAG="CLO835-FP"

echo -e "${YELLOW}Resources to be deleted:${NC}"
echo "- ECR Repository: $ECR_REPOSITORY"
echo "- EKS Cluster: $CLUSTER_NAME"
echo "- VPC and associated resources (subnets, security groups, etc.)"
echo "- Any resources tagged with: $PROJECT_TAG"
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

# Step 5: Clean up VPC and associated resources
echo -e "${BLUE}Step 5: Cleaning up VPC and network resources${NC}"

# Find VPCs with project tag
VPC_IDS=$(aws ec2 describe-vpcs --region "$REGION" --filters "Name=tag:Name,Values=*$PROJECT_TAG*" --query 'Vpcs[*].VpcId' --output text)

if [[ -n "$VPC_IDS" ]]; then
    echo "Found VPCs with project tag: $VPC_IDS"
    
    for VPC_ID in $VPC_IDS; do
        echo "Processing VPC: $VPC_ID"
        
        # Delete NAT Gateways
        NAT_GATEWAYS=$(aws ec2 describe-nat-gateways --region "$REGION" --filter "Name=vpc-id,Values=$VPC_ID" --query 'NatGateways[?State!=deleted].NatGatewayId' --output text)
        if [[ -n "$NAT_GATEWAYS" ]]; then
            echo "Deleting NAT Gateways: $NAT_GATEWAYS"
            for NAT_ID in $NAT_GATEWAYS; do
                aws ec2 delete-nat-gateway --nat-gateway-id "$NAT_ID" --region "$REGION"
                echo "Waiting for NAT Gateway $NAT_ID to be deleted..."
                aws ec2 wait nat-gateway-deleted --nat-gateway-ids "$NAT_ID" --region "$REGION"
            done
        fi
        
        # Delete Elastic IPs
        EIP_IDS=$(aws ec2 describe-addresses --region "$REGION" --filters "Name=domain,Values=vpc" --query 'Addresses[?AssociationId==null].AllocationId' --output text)
        if [[ -n "$EIP_IDS" ]]; then
            echo "Deleting unassociated Elastic IPs: $EIP_IDS"
            for EIP_ID in $EIP_IDS; do
                aws ec2 release-address --allocation-id "$EIP_ID" --region "$REGION" || true
            done
        fi
        
        # Delete Internet Gateways
        IGW_IDS=$(aws ec2 describe-internet-gateways --region "$REGION" --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query 'InternetGateways[*].InternetGatewayId' --output text)
        if [[ -n "$IGW_IDS" ]]; then
            echo "Deleting Internet Gateways: $IGW_IDS"
            for IGW_ID in $IGW_IDS; do
                aws ec2 detach-internet-gateway --internet-gateway-id "$IGW_ID" --vpc-id "$VPC_ID" --region "$REGION" || true
                aws ec2 delete-internet-gateway --internet-gateway-id "$IGW_ID" --region "$REGION"
            done
        fi
        
        # Delete Route Tables (except main)
        ROUTE_TABLES=$(aws ec2 describe-route-tables --region "$REGION" --filters "Name=vpc-id,Values=$VPC_ID" "Name=association.main,Values=false" --query 'RouteTables[*].RouteTableId' --output text)
        if [[ -n "$ROUTE_TABLES" ]]; then
            echo "Deleting Route Tables: $ROUTE_TABLES"
            for RT_ID in $ROUTE_TABLES; do
                # Delete route table associations first
                ASSOCIATIONS=$(aws ec2 describe-route-tables --region "$REGION" --route-table-ids "$RT_ID" --query 'RouteTables[0].Associations[?Main!=true].RouteTableAssociationId' --output text)
                for ASSOC_ID in $ASSOCIATIONS; do
                    aws ec2 disassociate-route-table --association-id "$ASSOC_ID" --region "$REGION" || true
                done
                aws ec2 delete-route-table --route-table-id "$RT_ID" --region "$REGION"
            done
        fi
        
        # Delete Subnets
        SUBNET_IDS=$(aws ec2 describe-subnets --region "$REGION" --filters "Name=vpc-id,Values=$VPC_ID" --query 'Subnets[*].SubnetId' --output text)
        if [[ -n "$SUBNET_IDS" ]]; then
            echo "Deleting Subnets: $SUBNET_IDS"
            for SUBNET_ID in $SUBNET_IDS; do
                aws ec2 delete-subnet --subnet-id "$SUBNET_ID" --region "$REGION"
            done
        fi
        
        # Delete Security Groups (except default)
        SG_IDS=$(aws ec2 describe-security-groups --region "$REGION" --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=!default" --query 'SecurityGroups[*].GroupId' --output text)
        if [[ -n "$SG_IDS" ]]; then
            echo "Deleting Security Groups: $SG_IDS"
            for SG_ID in $SG_IDS; do
                aws ec2 delete-security-group --group-id "$SG_ID" --region "$REGION" || true
            done
        fi
        
        # Delete Network ACLs (except default)
        NACL_IDS=$(aws ec2 describe-network-acls --region "$REGION" --filters "Name=vpc-id,Values=$VPC_ID" "Name=default,Values=false" --query 'NetworkAcls[*].NetworkAclId' --output text)
        if [[ -n "$NACL_IDS" ]]; then
            echo "Deleting Network ACLs: $NACL_IDS"
            for NACL_ID in $NACL_IDS; do
                aws ec2 delete-network-acl --network-acl-id "$NACL_ID" --region "$REGION"
            done
        fi
        
        # Finally delete the VPC
        echo "Deleting VPC: $VPC_ID"
        aws ec2 delete-vpc --vpc-id "$VPC_ID" --region "$REGION"
        echo "VPC $VPC_ID deleted successfully"
    done
else
    echo "No VPCs found with project tag"
fi
echo

# Step 6: Clean up any remaining resources with project tag
echo -e "${BLUE}Step 6: Cleaning up any remaining resources with project tag${NC}"

# Delete any remaining EC2 instances
EC2_INSTANCES=$(aws ec2 describe-instances --region "$REGION" --filters "Name=tag:Name,Values=*$PROJECT_TAG*" "Name=instance-state-name,Values=running,stopped" --query 'Reservations[*].Instances[*].InstanceId' --output text)
if [[ -n "$EC2_INSTANCES" ]]; then
    echo "Deleting EC2 instances: $EC2_INSTANCES"
    aws ec2 terminate-instances --instance-ids $EC2_INSTANCES --region "$REGION"
    echo "Waiting for instances to terminate..."
    aws ec2 wait instance-terminated --instance-ids $EC2_INSTANCES --region "$REGION"
fi

# Delete any remaining EBS volumes
EBS_VOLUMES=$(aws ec2 describe-volumes --region "$REGION" --filters "Name=tag:Name,Values=*$PROJECT_TAG*" "Name=status,Values=available" --query 'Volumes[*].VolumeId' --output text)
if [[ -n "$EBS_VOLUMES" ]]; then
    echo "Deleting EBS volumes: $EBS_VOLUMES"
    for VOLUME_ID in $EBS_VOLUMES; do
        aws ec2 delete-volume --volume-id "$VOLUME_ID" --region "$REGION"
    done
fi

# Delete any remaining Load Balancers
LB_ARNs=$(aws elbv2 describe-load-balancers --region "$REGION" --query 'LoadBalancers[?contains(LoadBalancerName, `'$PROJECT_TAG'`)].LoadBalancerArn' --output text)
if [[ -n "$LB_ARNs" ]]; then
    echo "Deleting Load Balancers: $LB_ARNs"
    for LB_ARN in $LB_ARNs; do
        aws elbv2 delete-load-balancer --load-balancer-arn "$LB_ARN" --region "$REGION"
    done
fi

# Delete any remaining Target Groups
TG_ARNs=$(aws elbv2 describe-target-groups --region "$REGION" --query 'TargetGroups[?contains(TargetGroupName, `'$PROJECT_TAG'`)].TargetGroupArn' --output text)
if [[ -n "$TG_ARNs" ]]; then
    echo "Deleting Target Groups: $TG_ARNs"
    for TG_ARN in $TG_ARNs; do
        aws elbv2 delete-target-group --target-group-arn "$TG_ARN" --region "$REGION"
    done
fi

echo "Remaining resources cleanup completed"
echo

# Summary
echo -e "${GREEN}=== Infrastructure Cleanup Complete ===${NC}"
echo -e "${YELLOW}Resources Deleted:${NC}"
echo "✓ EKS Cluster: $CLUSTER_NAME"
echo "✓ ECR Repository: $ECR_REPOSITORY"
echo "✓ Kubernetes namespace and resources"
echo "✓ VPC and associated network resources"
echo "✓ Any resources tagged with: $PROJECT_TAG"
echo
echo -e "${GREEN}All AWS resources have been cleaned up!${NC}"