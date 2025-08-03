# CLO835 Final Project - Complete Deployment Guide

## Table of Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Quick Start](#quick-start)
4. [Step-by-Step Deployment](#step-by-step-deployment)
5. [Verification and Testing](#verification-and-testing)
6. [Troubleshooting](#troubleshooting)
7. [Cleanup](#cleanup)

## Overview

This guide provides complete instructions for deploying the CLO835 Final Project, which includes:

- **Flask Web Application** with S3 background image integration
- **MySQL Database** with persistent storage
- **Amazon EKS** cluster for container orchestration
- **Amazon ECR** for private Docker image registry
- **Amazon S3** for private background image storage
- **GitHub Actions** CI/CD pipeline
- **Terraform** infrastructure as code

### Architecture Overview

```
Internet → ALB → EKS Cluster → Webapp Pods → MySQL Pods
                     ↓              ↓
                S3 Bucket      EBS Volumes
                     ↓
                ECR Registry
```

## Prerequisites

### Required Tools
- **Docker** (v20.10+) - Container runtime
- **AWS CLI** (v2.0+) - AWS command line interface
- **kubectl** (v1.21+) - Kubernetes command line tool
- **Terraform** (v1.0+) - Infrastructure as code
- **eksctl** (recommended) - EKS cluster management
- **Git** - Source code management

### AWS Account Requirements
- AWS account with appropriate permissions
- IAM permissions for EKS, ECR, S3, VPC, EC2
- AWS CLI configured with credentials
- Billing alerts recommended (resources cost ~$100-150/month)

### GitHub Requirements
- GitHub account with repository access
- GitHub Actions enabled
- Repository secrets configured

### System Requirements
- Unix-like environment (Linux, macOS, WSL2)
- 4GB+ RAM for local Docker testing
- Internet connection for AWS and GitHub access

## Quick Start

For experienced users who want to deploy everything at once:

```bash
# 1. Validate prerequisites
./scripts/validate-prerequisites.sh

# 2. Deploy everything
./scripts/deploy-complete.sh

# 3. Test functionality
./scripts/test-functionality.sh

# 4. Access application (get URL from output)
kubectl get service webapp-service -n clo835
```

## Step-by-Step Deployment

### Step 1: Environment Setup

1. **Clone the repository:**
   ```bash
   git clone <your-repo-url>
   cd clo835_summer2025_fp
   ```

2. **Validate prerequisites:**
   ```bash
   ./scripts/validate-prerequisites.sh
   ```

3. **Configure AWS credentials:**
   ```bash
   aws configure
   # Enter your AWS Access Key ID
   # Enter your AWS Secret Access Key
   # Enter region: us-east-1
   # Enter output format: json
   ```

4. **Verify AWS access:**
   ```bash
   aws sts get-caller-identity
   aws eks list-clusters --region us-east-1
   ```

### Step 2: GitHub Actions Setup

1. **Configure GitHub Secrets:**
   Go to your GitHub repository → Settings → Secrets and variables → Actions

   Add the following repository secrets:
   ```
   AWS_ACCESS_KEY_ID=your_access_key
   AWS_SECRET_ACCESS_KEY=your_secret_key
   AWS_REGION=us-east-1
   ECR_REPOSITORY=your_ecr_repo_name
   ```

2. **Trigger initial build:**
   ```bash
   git add .
   git commit -m "Initial setup for CLO835 Final Project"
   git push origin main
   ```

3. **Monitor GitHub Actions:**
   - Go to Actions tab in your GitHub repository
   - Watch the CI/CD pipeline build and push to ECR
   - Verify the Docker image is created successfully

### Step 3: Infrastructure Deployment

1. **Navigate to Terraform directory:**
   ```bash
   cd terraform
   ```

2. **Configure Terraform variables:**
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your specific values
   ```

3. **Initialize and deploy Terraform:**
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

4. **Note the outputs:**
   ```bash
   terraform output
   # Record cluster_name, cluster_endpoint, ecr_repository_url
   ```

### Step 4: Kubernetes Configuration

1. **Configure kubectl for EKS:**
   ```bash
   aws eks update-kubeconfig --region us-east-1 --name <cluster-name>
   ```

2. **Verify cluster access:**
   ```bash
   kubectl cluster-info
   kubectl get nodes
   ```

### Step 5: S3 Setup

1. **Create S3 bucket for background images:**
   ```bash
   aws s3 mb s3://your-unique-bucket-name --region us-east-1
   ```

2. **Upload background image:**
   ```bash
   aws s3 cp background.jpg s3://your-bucket-name/background.jpg
   ```

3. **Update bucket policy for private access:**
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Deny",
         "Principal": "*",
         "Action": "s3:GetObject",
         "Resource": "arn:aws:s3:::your-bucket-name/*",
         "Condition": {
           "Bool": {
             "aws:SecureTransport": "false"
           }
         }
       }
     ]
   }
   ```

### Step 6: Kubernetes Secrets Configuration

1. **Create AWS credentials secret:**
   ```bash
   kubectl create secret generic aws-secret \
     --from-literal=AWS_ACCESS_KEY_ID=your_key \
     --from-literal=AWS_SECRET_ACCESS_KEY=your_secret \
     -n clo835
   ```

2. **Create MySQL credentials secret:**
   ```bash
   kubectl create secret generic mysql-secret \
     --from-literal=DBUSER=root \
     --from-literal=DBPWD=password \
     -n clo835
   ```

3. **Create ECR pull secret:**
   ```bash
   kubectl create secret docker-registry ecr-secret \
     --docker-server=<account-id>.dkr.ecr.us-east-1.amazonaws.com \
     --docker-username=AWS \
     --docker-password=$(aws ecr get-login-password --region us-east-1) \
     -n clo835
   ```

### Step 7: ConfigMap Configuration

1. **Update ConfigMap with your S3 URL:**
   ```bash
   kubectl edit configmap webapp-config -n clo835
   ```

   Update the BACKGROUND_IMAGE_URL:
   ```yaml
   data:
     BACKGROUND_IMAGE_URL: "s3://your-bucket-name/background.jpg"
     GROUP_NAME: "Your Group Name"
     GROUP_SLOGAN: "Your Group Slogan"
   ```

### Step 8: Application Deployment

1. **Deploy Kubernetes manifests:**
   ```bash
   cd k8s-manifests
   ./deploy.sh
   ```

   Or deploy manually:
   ```bash
   kubectl apply -f namespace.yaml
   kubectl apply -f rbac.yaml
   kubectl apply -f configmap.yaml
   kubectl apply -f secrets.yaml
   kubectl apply -f pvc.yaml
   kubectl apply -f mysql-deployment.yaml
   kubectl apply -f mysql-service.yaml
   kubectl apply -f webapp-deployment.yaml
   kubectl apply -f webapp-service.yaml
   ```

2. **Wait for deployments to be ready:**
   ```bash
   kubectl wait --for=condition=available --timeout=300s deployment/mysql-deployment -n clo835
   kubectl wait --for=condition=available --timeout=300s deployment/webapp-deployment -n clo835
   ```

## Verification and Testing

### Quick Health Check

```bash
# Check all resources
kubectl get all -n clo835

# Check pod logs
kubectl logs -l app=webapp -n clo835
kubectl logs -l app=mysql -n clo835

# Check services
kubectl get services -n clo835
```

### Application Access

1. **Get LoadBalancer URL:**
   ```bash
   kubectl get service webapp-service -n clo835
   # Wait for EXTERNAL-IP to be assigned
   ```

2. **Access application:**
   ```bash
   # Use the external IP/hostname from above
   curl http://<external-ip>
   # Or open in browser
   ```

### Comprehensive Testing

```bash
# Run full functionality tests
./scripts/test-functionality.sh

# Run quick tests only
./scripts/test-functionality.sh --quick
```

### Manual Testing Checklist

- [ ] Application loads in browser
- [ ] Background image displays correctly
- [ ] Add employee functionality works
- [ ] Get employee functionality works
- [ ] Data persists after MySQL pod restart
- [ ] ConfigMap updates reflect new background image

### Testing ConfigMap Updates

1. **Update background image URL:**
   ```bash
   kubectl edit configmap webapp-config -n clo835
   # Change BACKGROUND_IMAGE_URL to new S3 image
   ```

2. **Restart webapp pods:**
   ```bash
   kubectl rollout restart deployment/webapp-deployment -n clo835
   ```

3. **Verify new background:**
   - Refresh browser
   - Check application logs for new image URL

### Testing Data Persistence

1. **Add test data:**
   ```bash
   # Use web interface to add employee data
   ```

2. **Delete MySQL pod:**
   ```bash
   kubectl delete pod -l app=mysql -n clo835
   ```

3. **Verify data persistence:**
   ```bash
   # Wait for pod to restart
   kubectl wait --for=condition=ready pods -l app=mysql -n clo835
   # Check if data still exists via web interface
   ```

## Troubleshooting

### Common Issues

#### 1. Pods Not Starting

**Symptoms:**
- Pods stuck in Pending, CrashLoopBackOff, or ImagePullBackOff

**Solutions:**
```bash
# Check pod status and events
kubectl describe pod <pod-name> -n clo835

# Check resource availability
kubectl top nodes
kubectl get pvc -n clo835

# For ImagePullBackOff, update ECR secret
kubectl delete secret ecr-secret -n clo835
kubectl create secret docker-registry ecr-secret \
  --docker-server=<account-id>.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password --region us-east-1) \
  -n clo835
```

#### 2. Database Connection Issues

**Symptoms:**
- Webapp logs show database connection errors

**Solutions:**
```bash
# Check MySQL pod status
kubectl logs -l app=mysql -n clo835

# Verify service connectivity
kubectl exec -it deploy/webapp-deployment -n clo835 -- nc -zv mysql-service 3306

# Check secrets
kubectl get secret mysql-secret -n clo835 -o yaml
```

#### 3. LoadBalancer Not Getting External IP

**Symptoms:**
- Service stuck in `<pending>` state

**Solutions:**
```bash
# Check AWS Load Balancer Controller
kubectl get pods -n kube-system | grep aws-load-balancer

# Check service events
kubectl describe service webapp-service -n clo835

# Verify IAM permissions for EKS service role
aws iam list-attached-role-policies --role-name <eks-node-group-role>
```

#### 4. S3 Image Not Loading

**Symptoms:**
- Background image not displaying, S3 errors in logs

**Solutions:**
```bash
# Check AWS credentials secret
kubectl get secret aws-secret -n clo835 -o yaml

# Test S3 access from pod
kubectl exec -it deploy/webapp-deployment -n clo835 -- aws s3 ls s3://your-bucket-name/

# Verify IAM permissions
aws iam simulate-principal-policy \
  --policy-source-arn <role-arn> \
  --action-names s3:GetObject \
  --resource-arns arn:aws:s3:::your-bucket-name/*
```

#### 5. GitHub Actions Failing

**Symptoms:**
- CI/CD pipeline fails to build or push to ECR

**Solutions:**
```bash
# Check GitHub repository secrets
# Verify AWS credentials have ECR permissions
aws ecr describe-repositories --region us-east-1

# Update ECR login token in workflow
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
```

### Debug Commands

```bash
# Pod debugging
kubectl get pods -n clo835 -o wide
kubectl describe pod <pod-name> -n clo835
kubectl logs <pod-name> -n clo835 --previous

# Service debugging
kubectl get svc -n clo835
kubectl get endpoints -n clo835
kubectl describe svc webapp-service -n clo835

# Storage debugging
kubectl get pv,pvc -n clo835
kubectl describe pvc mysql-pvc -n clo835

# Network debugging
kubectl exec -it deploy/webapp-deployment -n clo835 -- nc -zv mysql-service 3306
kubectl exec -it deploy/webapp-deployment -n clo835 -- nslookup mysql-service
```

### Log Analysis

```bash
# Application logs
kubectl logs -f deploy/webapp-deployment -n clo835

# Database logs
kubectl logs -f deploy/mysql-deployment -n clo835

# System logs
kubectl get events -n clo835 --sort-by='.lastTimestamp'
```

## Cleanup

### Quick Cleanup

```bash
# Remove all project resources
./scripts/cleanup-all.sh
```

### Manual Cleanup

1. **Remove Kubernetes resources:**
   ```bash
   kubectl delete namespace clo835
   ```

2. **Destroy Terraform infrastructure:**
   ```bash
   cd terraform
   terraform destroy
   ```

3. **Clean up ECR images:**
   ```bash
   aws ecr list-images --repository-name <repo-name> --region us-east-1
   aws ecr batch-delete-image --repository-name <repo-name> --region us-east-1 --image-ids imageTag=latest
   ```

4. **Remove S3 bucket:**
   ```bash
   aws s3 rm s3://your-bucket-name --recursive
   aws s3 rb s3://your-bucket-name
   ```

### Cost Management

**Important:** Always clean up resources to avoid unexpected charges!

Estimated monthly costs:
- EKS cluster: ~$72/month
- Worker nodes (t3.medium): ~$69/month each
- Load Balancer: ~$16-23/month
- EBS volumes: ~$0.10/GB/month
- ECR storage: Variable based on image size

## Additional Resources

- [EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)

## Support

For issues with this deployment:

1. Check the troubleshooting section above
2. Review application logs using kubectl
3. Verify AWS permissions and quotas
4. Check GitHub Actions workflow logs
5. Consult AWS documentation for service-specific issues

---

**Note:** This deployment guide assumes familiarity with AWS, Kubernetes, and containerization concepts. Always follow AWS best practices for security and cost management.