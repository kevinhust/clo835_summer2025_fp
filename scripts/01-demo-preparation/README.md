# 01 - Demo Preparation Phase

## Overview
This phase prepares GitHub Actions CI/CD pipeline and EKS infrastructure for the CLO835 Final Project demo. The focus is on demonstrating automated deployment capabilities.

⏱️ **Estimated Time**: 5-10 minutes (GitHub Actions and eksctl handle the heavy lifting)

## Prerequisites Check

### 1. AWS CLI Configuration
```bash
# Verify AWS CLI is configured
aws sts get-caller-identity

# Expected output shows your AWS account details
# If not configured, run: aws configure
```

### 2. Required Tools Installation
```bash
# Check kubectl
kubectl version --client

# Check eksctl  
eksctl version

# Check Docker
docker --version

# If any tool is missing, install following AWS documentation
```

### 3. GitHub Repository Setup
- Ensure your repository has GitHub Actions enabled
- Set GitHub Secrets:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`  
  - `AWS_REGION` (us-east-1)
  - `ECR_REPOSITORY` (clo835fp-webapp)
  - `S3_BUCKET_NAME` (clo835fp-bg-images)

## Infrastructure Setup via eksctl

### Step 1: Verify S3 Bucket (Already Created)

✅ **S3 bucket `clo835fp-bg-images` is already created with background images:**
- blue-theme.jpg
- default-bg.jpg  
- green-theme.jpg
- professional-bg.jpg

```bash
# Verify S3 bucket contents
aws s3 ls s3://clo835fp-bg-images/background-images/ --human-readable
```

### Step 2: Create EKS Infrastructure via eksctl

```bash
# Set cluster name
export CLUSTER_NAME="clo835-eks-cluster"
export REGION="us-east-1"

# Create EKS cluster using the provided eks-cluster.yaml
eksctl create cluster -f eks-cluster.yaml

# This takes 15-20 minutes and automatically creates:
# - EKS cluster control plane
# - Worker node group (2 t3.medium instances)
# - VPC with subnets and security groups
# - IAM roles and service accounts
# - ECR repository
```

### Step 3: Update Kubeconfig

```bash
# Update kubeconfig to connect to the new cluster
aws eks update-kubeconfig --region $REGION --name $CLUSTER_NAME

# Verify connection
kubectl get nodes
kubectl get namespaces
```

## GitHub Actions Pipeline Setup

### Step 4: Verify GitHub Actions Workflow

Check that `.github/workflows/ci-cd.yml` contains:
- Docker build and test
- ECR repository creation (if not exists)
- Image push to ECR with automated tagging
- EKS deployment automation
- Security scanning with Trivy

### Step 5: Test Local Docker Build (Optional)

```bash
# Build Docker image locally to test
docker build -t webapp:latest .

# Test locally (optional)
docker run -p 8080:81 webapp:latest
# Test at http://localhost:8080 then stop with Ctrl+C
```

## Trigger GitHub Actions Deployment

### Step 6: Trigger Automated CI/CD Pipeline

```bash
# Make a small change to trigger GitHub Actions
echo "# Demo setup timestamp: $(date)" >> README.md
git add README.md
git commit -m "Trigger CI/CD pipeline for demo setup"
git push origin main

# GitHub Actions will automatically:
# 1. Build Docker image
# 2. Create ECR repository (if not exists)  
# 3. Push image to ECR
# 4. Deploy to EKS cluster
# 5. Run security scans
```

## Final Verification

### Step 7: Pre-Demo Checklist

```bash
# Set environment variables
export AWS_REGION="us-east-1"
export S3_BUCKET="clo835fp-bg-images"
export ECR_REPOSITORY="clo835fp-webapp"
export CLUSTER_NAME="clo835-eks-cluster"
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export NAMESPACE="fp"

# 1. Verify S3 bucket and images (already created)
aws s3 ls s3://$S3_BUCKET/background-images/ --human-readable

# 2. Verify EKS cluster
kubectl get nodes
kubectl get namespaces

# 3. Check GitHub Actions workflow status
# Visit: https://github.com/YOUR_USERNAME/YOUR_REPO/actions

# 4. Verify ECR repository created by GitHub Actions
aws ecr describe-repositories --repository-names $ECR_REPOSITORY --region $AWS_REGION || echo "ECR will be created by GitHub Actions"

# 5. Wait for GitHub Actions to complete deployment
kubectl get all -n fp || echo "Resources will be deployed by GitHub Actions"
```

## Environment Variables for Demo

```bash
# Create environment file for demo execution phase
cat << EOF > /tmp/demo-env.sh
export AWS_REGION="us-east-1"
export S3_BUCKET="clo835fp-bg-images"
export ECR_REPOSITORY="clo835fp-webapp"
export CLUSTER_NAME="clo835-eks-cluster"
export AWS_ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
export ECR_URI="\$AWS_ACCOUNT_ID.dkr.ecr.\$AWS_REGION.amazonaws.com/\$ECR_REPOSITORY"
export NAMESPACE="fp"
EOF

echo "Environment variables saved to /tmp/demo-env.sh"
echo "Source this file in demo execution: source /tmp/demo-env.sh"
```

## Infrastructure Cost Estimation

**Approximate costs for 30-minute demo:**
- EKS Cluster: ~$0.20 (control plane + worker nodes)
- S3 Storage: ~$0.01 (pre-existing bucket)
- ECR: ~$0.01 (minimal storage)
- **Total: ~$0.22 for 30 minutes**

## Troubleshooting Common Issues

### EKS Cluster Creation Fails
```bash
# Check AWS service limits
aws service-quotas get-service-quota --service-code eks --quota-code L-1194D53C

# Verify IAM permissions
aws iam get-role --role-name eksctl-clo835-eks-cluster-cluster-ServiceRole
```

### ECR Push Fails
```bash
# Re-authenticate with ECR
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ECR_URI

# Check repository exists
aws ecr describe-repositories --repository-names $ECR_REPOSITORY --region $REGION
```

### S3 Access Issues
```bash
# Verify bucket exists and you have access
aws s3 ls s3://$S3_BUCKET

# Check bucket policy
aws s3api get-bucket-policy --bucket $S3_BUCKET
```

---

✅ **Preparation Complete!** 

You're now ready to proceed to **02-demo-execution** phase.

**Next Step**: Go to `scripts/02-demo-execution/` for the main demonstration workflow.