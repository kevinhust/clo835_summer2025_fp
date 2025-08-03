# CLO835 Final Project - Terraform EKS Infrastructure

This directory contains the Terraform configuration for the CLO835 Final Project EKS infrastructure, redesigned from the reference EC2-based structure to support Kubernetes deployment.

## Overview

This infrastructure setup follows the CLO835 monolithic pattern (single `main.tf` file) for educational clarity while providing a production-ready EKS cluster with supporting services.

## Architecture

### Core Components

1. **VPC with Multi-AZ Setup**
   - 2 Public subnets (for Load Balancers)
   - 2 Private subnets (for EKS nodes)
   - NAT Gateways for private subnet internet access
   - Proper subnet tagging for EKS integration

2. **EKS Cluster**
   - Managed EKS cluster (`clo835-eks-cluster`)
   - 2-node managed node group (t3.small instances)
   - Kubernetes version 1.30
   - Proper IAM roles and security groups

3. **Supporting Services**
   - ECR repository for container images
   - Private S3 bucket for background images
   - Security groups with least-privilege access

### File Structure

```
terraform/
├── backend.tf              # S3 backend configuration
├── main.tf                 # All infrastructure resources (monolithic)
├── variables.tf            # Input variables
├── outputs.tf              # Output values for GitHub Actions
├── versions.tf             # Provider version constraints
├── terraform.tfvars.example # Example variable values
└── README.md               # This file
```

## Quick Start

### Prerequisites

1. AWS CLI configured with appropriate permissions
2. Terraform >= 1.0 installed
3. S3 bucket and DynamoDB table for state management:
   - Bucket: `clo835fp-terraform-state`
   - DynamoDB table: `clo835fp-terraform-lock`

### Setup

1. **Copy and customize variables:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your specific values
   ```

2. **Initialize Terraform:**
   ```bash
   terraform init
   ```

3. **Plan the deployment:**
   ```bash
   terraform plan
   ```

4. **Apply the configuration:**
   ```bash
   terraform apply
   ```

### Configuration

Key variables in `terraform.tfvars`:

```hcl
# AWS Region
region = "us-east-1"

# EKS Configuration
cluster_name = "clo835-eks-cluster"
node_instance_type = "t3.small"
node_desired_capacity = 2

# S3 Bucket (must be globally unique)
s3_bucket_name = "clo835fp-background-images-your-unique-suffix"
```

## Integration with GitHub Actions

This Terraform configuration is designed to work seamlessly with the GitHub Actions workflows:

### Terraform Workflow (`.github/workflows/terraform.yml`)

- **On Pull Request:** Runs `terraform plan` and comments results
- **On Main Branch:** Runs `terraform apply` and exports outputs
- **Outputs:** EKS cluster info, ECR repository URL, S3 bucket details

### CI/CD Workflow (`.github/workflows/ci-cd.yml`)

- **Integration:** Uses terraform outputs for deployment
- **EKS Connection:** Automatically configures kubectl with cluster
- **ECR Images:** Deploys to the created ECR repository

## Security Features

### Network Security
- Private subnets for EKS nodes
- Public subnets only for load balancers
- Security groups with minimal required access
- NAT Gateways for secure outbound access

### Data Security
- S3 bucket with encryption at rest
- ECR image scanning enabled
- Private bucket with public access blocked
- Versioning enabled on S3 bucket

### Access Control
- Least-privilege IAM roles for EKS
- Separate roles for cluster and nodes
- GitHub Actions integration via OIDC (no long-term keys)

## Outputs

The following outputs are available for integration:

```hcl
# EKS Information
eks_cluster_name           # For kubectl configuration
eks_cluster_endpoint       # API server endpoint
eks_cluster_arn           # Full ARN of the cluster

# Container Registry
ecr_repository_url        # For docker push/pull

# Storage
s3_bucket_name           # For application file storage
s3_bucket_region         # S3 bucket region

# Networking
vpc_id                   # VPC identifier
public_subnet_ids        # Public subnet IDs
private_subnet_ids       # Private subnet IDs
```

## Monitoring and Management

### State Management
- Remote state stored in S3 with encryption
- State locking via DynamoDB
- Versioning enabled for state file recovery

### Resource Tagging
All resources are tagged with:
- `Environment: production`
- `Project: CLO835-FinalProject`
- `Name: <resource-specific-name>`

## Troubleshooting

### Common Issues

1. **S3 Bucket Name Conflicts**
   - Error: "BucketAlreadyExists"
   - Solution: Update `s3_bucket_name` with a unique suffix

2. **EKS Node Group Failures**
   - Check subnet availability zones
   - Verify IAM role permissions
   - Ensure proper security group rules

3. **Terraform State Locks**
   - Check DynamoDB table for stuck locks
   - Use `terraform force-unlock` if necessary

### Validation Commands

```bash
# Verify EKS cluster
aws eks describe-cluster --name clo835-eks-cluster

# Check node group
aws eks describe-nodegroup --cluster-name clo835-eks-cluster --nodegroup-name clo835-eks-nodes

# Test kubectl connectivity
aws eks update-kubeconfig --name clo835-eks-cluster
kubectl get nodes
```

## Educational Notes

This configuration demonstrates:

1. **Infrastructure as Code** best practices
2. **AWS EKS** managed Kubernetes setup
3. **Multi-AZ** high availability patterns
4. **Security** best practices for cloud resources
5. **CI/CD Integration** with GitHub Actions
6. **State Management** for team collaboration

The monolithic structure (`main.tf`) is intentionally maintained for educational clarity, following the CLO835 assignment pattern while providing production-ready infrastructure.

## Next Steps

After successful deployment:

1. **Configure kubectl:** `aws eks update-kubeconfig --name clo835-eks-cluster`
2. **Deploy applications:** Use the K8s manifests in `../k8s-manifests/`
3. **Monitor resources:** Check AWS console for cluster health
4. **Scale as needed:** Adjust node group capacity via variables

For detailed deployment instructions, see the main project README.