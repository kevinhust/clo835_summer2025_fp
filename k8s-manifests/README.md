# CLO835 Final Project - Kubernetes Manifests

This directory contains comprehensive Kubernetes manifests for deploying the enhanced Flask application with S3 integration to Amazon EKS.

## Manifest Files Overview

### 1. `namespace.yaml`
- Creates the "fp" namespace for all project resources
- Provides resource isolation and organization

### 2. `configmap.yaml`
- Contains non-sensitive application configuration
- Includes S3 background image URL, group information, database settings
- **UPDATE REQUIRED**: Replace placeholder values with your actual configuration

### 3. `secrets.yaml`
- Contains sensitive data (passwords, AWS credentials, ECR access)
- All values are base64 encoded
- **UPDATE REQUIRED**: Replace placeholder values with your actual encoded credentials

### 4. `rbac.yaml`
- Creates ServiceAccount "clo835-sa"
- Defines ClusterRole "CLO835" with namespace permissions
- Binds role to service account for proper access control

### 5. `pvc.yaml`
- PersistentVolumeClaim for MySQL data storage
- Uses gp2 StorageClass with 3Gi capacity
- Ensures data persistence across pod restarts

### 6. `mysql-deployment.yaml`
- MySQL 8.0 deployment with persistent storage
- Uses secrets for database credentials
- Includes health checks and resource limits
- Mounts PVC to /var/lib/mysql for data persistence

### 7. `mysql-service.yaml`
- ClusterIP service for internal database access
- Exposes MySQL on port 3306 within the cluster
- Used by Flask application for database connections

### 8. `webapp-deployment.yaml`
- Flask application deployment with enhanced features
- Uses ECR image with imagePullSecrets
- Configures all environment variables from ConfigMaps and Secrets
- Includes health checks and resource limits
- **UPDATE REQUIRED**: Replace ECR image URI with your actual repository

### 9. `webapp-service.yaml`
- LoadBalancer service for external internet access
- Exposes application on port 80 (maps to container port 81)
- Provides stable endpoint for users

## Deployment Instructions

### Prerequisites
1. Amazon EKS cluster running
2. kubectl configured to access your EKS cluster
3. Docker image built and pushed to ECR
4. AWS credentials with S3 access
5. Background image uploaded to S3 bucket

### Step 1: Update Configuration
Before deployment, update the following files with your actual values:

#### `configmap.yaml`:
```yaml
data:
  BACKGROUND_IMAGE_URL: "s3://your-actual-bucket/your-image.jpg"
  GROUP_NAME: "Your Group Name"
  GROUP_SLOGAN: "Your Group Slogan"
```

#### `secrets.yaml`:
```bash
# Generate base64 encoded values:
echo -n "your-actual-db-user" | base64
echo -n "your-actual-db-password" | base64
echo -n "your-aws-access-key" | base64
echo -n "your-aws-secret-key" | base64
```

#### `webapp-deployment.yaml`:
```yaml
spec:
  template:
    spec:
      containers:
      - name: webapp
        image: YOUR_ACCOUNT.dkr.ecr.us-east-1.amazonaws.com/clo835-webapp:latest
```

### Step 2: Deploy to EKS
```bash
# Apply all manifests in order
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f secrets.yaml
kubectl apply -f rbac.yaml
kubectl apply -f pvc.yaml
kubectl apply -f mysql-deployment.yaml
kubectl apply -f mysql-service.yaml
kubectl apply -f webapp-deployment.yaml
kubectl apply -f webapp-service.yaml

# Or apply all at once
kubectl apply -f .
```

### Step 3: Verify Deployment
```bash
# Check namespace and resources
kubectl get all -n fp

# Check persistent volumes
kubectl get pv,pvc -n fp

# Check secrets and configmaps
kubectl get secrets,configmaps -n fp

# Get LoadBalancer external IP
kubectl get service webapp-service -n fp
```

### Step 4: Initialize Database
```bash
# Copy SQL file to MySQL pod
kubectl cp ../mysql.sql mysql-deployment-<pod-id>:/tmp/ -n fp

# Execute SQL initialization
kubectl exec -it mysql-deployment-<pod-id> -n fp -- mysql -u root -p employees < /tmp/mysql.sql
```

## Security Best Practices
- All sensitive data stored in Kubernetes Secrets
- ServiceAccount with minimal required permissions
- Resource limits defined for all containers
- Health checks configured for reliability
- Secrets mounted as environment variables (not files)

## Monitoring and Troubleshooting
```bash
# View pod logs
kubectl logs -f deployment/webapp-deployment -n fp
kubectl logs -f deployment/mysql-deployment -n fp

# Describe resources for detailed status
kubectl describe deployment webapp-deployment -n fp
kubectl describe service webapp-service -n fp

# Check events for issues
kubectl get events -n fp --sort-by='.lastTimestamp'
```

## Architecture Overview
```
Internet
    ↓
LoadBalancer Service (webapp-service)
    ↓
WebApp Deployment (Flask App)
    ↓
ClusterIP Service (mysql-service)
    ↓
MySQL Deployment
    ↓
PersistentVolume (mysql data)
```

## Important Notes
- Ensure ECR repository exists and image is pushed before deployment
- Update AWS credentials and S3 configuration before deployment
- MySQL data persists across pod restarts due to PVC
- LoadBalancer service may take a few minutes to provision external IP
- All resources are deployed in the "fp" namespace as required

## Clean Up
```bash
# Remove all resources
kubectl delete namespace fp

# This will remove all resources in the namespace
```