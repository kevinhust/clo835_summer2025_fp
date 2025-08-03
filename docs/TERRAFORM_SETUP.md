# CLO835 Final Project - Terraform Setup Guide

## Overview

This guide walks you through setting up the EKS infrastructure using the redesigned Terraform configuration based on the CLO835 assignment reference structure.

## Prerequisites

1. **AWS Account** with sufficient permissions
2. **AWS CLI** configured
3. **Terraform** >= 1.0 installed
4. **kubectl** for Kubernetes management
5. **GitHub repository** with Actions enabled

## Phase 4: Infrastructure Setup

### Step 1: Prepare Backend Storage

Create the S3 bucket and DynamoDB table for Terraform state:

```bash
# Create S3 bucket for state
aws s3 mb s3://clo835fp-terraform-state --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket clo835fp-terraform-state \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name clo835fp-terraform-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
  --region us-east-1
```

### Step 2: Configure Terraform Variables

```bash
cd terraform

# Copy and customize the example file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your specific values
# IMPORTANT: Change s3_bucket_name to something globally unique
vi terraform.tfvars
```

Key variables to customize:

```hcl
# Make this globally unique
s3_bucket_name = "clo835fp-background-images-your-initials-$(date +%s)"

# Other variables (defaults should work)
region = "us-east-1"
cluster_name = "clo835-eks-cluster"
node_instance_type = "t3.small"
node_desired_capacity = 2
```

### Step 3: Deploy Infrastructure

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

**Expected Resources Created:**
- VPC with 4 subnets (2 public, 2 private)
- EKS cluster with 2 worker nodes
- ECR repository for container images
- Private S3 bucket for background images
- IAM roles and security groups

### Step 4: Configure kubectl

```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name clo835-eks-cluster

# Verify connection
kubectl get nodes
kubectl get namespaces
```

### Step 5: Deploy Applications

```bash
# Navigate back to project root
cd ..

# Deploy K8s manifests
kubectl apply -f k8s-manifests/

# Verify deployment
kubectl get pods -n clo835
kubectl get services -n clo835
```

## GitHub Actions Integration

### Required Secrets

Configure these secrets in your GitHub repository:

1. **For AWS Authentication (OIDC):**
   ```
   AWS_ROLE_ARN: arn:aws:iam::ACCOUNT_ID:role/GitHubActionsRole
   ECR_REPOSITORY_URI: ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/clo835fp-webapp
   ```

2. **For Kubernetes Deployment:**
   ```
   EKS_CLUSTER_NAME: clo835-eks-cluster
   ```

### Workflow Trigger

The workflows will trigger automatically:

1. **Terraform workflow** (`terraform.yml`):
   - On PR: Plans infrastructure changes
   - On main push: Applies changes and outputs values

2. **CI/CD workflow** (`ci-cd.yml`):
   - Triggered by terraform completion
   - Builds and deploys application to EKS

## Architecture Comparison

### Before (EC2 + KIND)
```
EC2 Instance
├── Docker
├── KIND Cluster
├── Local Registry
└── Manual Deployment
```

### After (EKS + GitHub Actions)
```
AWS EKS
├── Managed Node Group (2 nodes)
├── ECR Repository
├── S3 Storage
├── Automated CI/CD
└── Load Balancer Integration
```

## Key Benefits

1. **Production Ready**: Managed EKS service with HA
2. **Automated**: GitHub Actions for CI/CD
3. **Scalable**: Auto-scaling node groups
4. **Secure**: Private networks, IAM roles, encryption
5. **Cost Effective**: t3.small nodes, spot instances available

## Troubleshooting

### Common Issues

**1. S3 Bucket Already Exists**
```bash
# Error: "BucketAlreadyExists"
# Solution: Use a unique bucket name in terraform.tfvars
s3_bucket_name = "clo835fp-bg-images-$(whoami)-$(date +%s)"
```

**2. EKS Node Launch Failures**
```bash
# Check node group status
aws eks describe-nodegroup --cluster-name clo835-eks-cluster --nodegroup-name clo835-eks-nodes

# Common causes:
# - Insufficient EC2 capacity in AZ
# - IAM role permission issues
# - Security group conflicts
```

**3. kubectl Connection Issues**
```bash
# Re-configure kubeconfig
aws eks update-kubeconfig --region us-east-1 --name clo835-eks-cluster --profile your-profile

# Verify AWS credentials
aws sts get-caller-identity
```

### Cleanup

To destroy all resources:

```bash
# Destroy Kubernetes resources first
kubectl delete -f k8s-manifests/

# Then destroy infrastructure
cd terraform
terraform destroy
```

## Educational Value

This setup demonstrates:

1. **Infrastructure as Code**: Terraform best practices
2. **Cloud Native**: Kubernetes on AWS EKS
3. **CI/CD Integration**: GitHub Actions automation
4. **Security**: IAM roles, private networks, encryption
5. **Monitoring**: CloudWatch integration for EKS
6. **Cost Management**: Right-sized resources

## Next Steps

1. **Monitoring**: Add CloudWatch dashboards
2. **Scaling**: Configure HPA for applications
3. **Security**: Implement Pod Security Standards
4. **Networking**: Add Ingress controllers
5. **Storage**: Persistent volume management

This infrastructure provides a solid foundation for modern cloud-native applications while maintaining the educational clarity of the CLO835 assignment structure.