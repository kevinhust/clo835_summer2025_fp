# 02 - Demo Execution Phase

## Overview
This is the main 30-minute demonstration phase showing all CLO835 Final Project requirements. Follow this exact sequence for a smooth presentation.

⏱️ **Target Time**: 30 minutes total
- Setup verification: 3 minutes
- Application deployment: 8 minutes  
- Feature demonstrations: 15 minutes
- Q&A buffer: 4 minutes

## Pre-Demo Setup

### Load Environment Variables
```bash
# Source the environment file from preparation phase
source /tmp/demo-env.sh

# Verify all variables are set
echo "AWS Account: $AWS_ACCOUNT_ID"
echo "Region: $AWS_REGION" 
echo "S3 Bucket: $S3_BUCKET"
echo "ECR URI: $ECR_URI"
echo "EKS Cluster: $CLUSTER_NAME"
echo "Namespace: $NAMESPACE"
```

### Quick Infrastructure Verification
```bash
# 1. Verify EKS cluster connection
kubectl get nodes
kubectl get namespaces

# 2. Verify ECR image exists
aws ecr list-images --repository-name $ECR_REPOSITORY --region $AWS_REGION

# 3. Verify S3 background images
aws s3 ls s3://$S3_BUCKET/background-images/ --human-readable
```

## Demo Script (30 Minutes)

### Part 1: Project Introduction (2 minutes)

**🎤 Narration Script:**
> "Hello! Today I'll demonstrate my CLO835 Final Project - a containerized Flask employee management application deployed on Amazon EKS with complete CI/CD pipeline and AWS S3 integration."

> "This project demonstrates cloud-native development practices including containerization with Docker, orchestration with Kubernetes, infrastructure on AWS EKS, and automated deployment through GitHub Actions."

**🖥️ Show:** Project directory structure
```bash
# Navigate to project root and show structure
ls -la

# Highlight key files
echo "Key files in this project:"
echo "• app.py - Flask application"
echo "• Dockerfile - Multi-stage container build"  
echo "• k8s-manifests/ - Kubernetes deployment files"
echo "• eks-cluster.yaml - EKS cluster configuration"
```

### Part 2: Local Docker Testing (3 minutes)

**🎤 Narration:**
> "First, let me demonstrate the application running locally using Docker to show it works before deploying to Kubernetes."

```bash
# Build Docker image locally
docker build -t webapp:latest .

# Show the multi-stage Dockerfile
head -20 Dockerfile

# Run container locally
docker run -d -p 8080:81 --name local-test webapp:latest

# Test the application
curl -I http://localhost:8080
```

**🌐 Browser Demo:**
- Open http://localhost:8080
- Navigate through the employee management interface
- Show "Add Employee" and "Get Employee" functionality
- Point out the background image loading

```bash
# Stop local container
docker stop local-test
docker rm local-test
```

### Part 3: GitHub Actions CI/CD Pipeline (6 minutes)

**🎤 Narration:**
> "The core of this project is the automated GitHub Actions CI/CD pipeline that handles the entire deployment process from code push to production on EKS."

**🖥️ Show GitHub Repository:**
- Navigate to GitHub repository
- Show `.github/workflows/ci-cd.yml` file
- Explain the automated pipeline stages:
  - **Build Stage**: Docker multi-stage build with security scanning
  - **Test Stage**: Automated testing and code quality checks
  - **Security Stage**: Trivy vulnerability scanning
  - **Deploy Stage**: ECR push + EKS deployment automation
  - **Verification Stage**: Post-deployment health checks

**🔄 Demonstrate Live Deployment:**
```bash
# Make a meaningful change to trigger the full pipeline
echo "# Live demo deployment: $(date)" >> app.py
git add app.py
git commit -m "Live demo: Trigger full CI/CD pipeline - $(date)"
git push origin main
```

**🌐 Browser Demo:**
- Show GitHub Actions tab real-time
- Highlight the pipeline automation:
  - ✅ **ECR Repository Creation**: Automatic ECR setup if not exists
  - ✅ **Docker Build & Push**: Multi-stage build with automated tagging
  - ✅ **Security Scanning**: Trivy vulnerability detection
  - ✅ **EKS Deployment**: Kubectl apply with rolling updates
  - ✅ **Health Checks**: Automated verification of deployment success

**🎤 Key Points:**
> "Notice how the pipeline automatically handles infrastructure provisioning, security scanning, and deployment without any manual intervention. This demonstrates true CI/CD automation."

### Part 4: EKS Infrastructure & Automated Deployment (6 minutes)

**🎤 Narration:**
> "While GitHub Actions handles the deployment, let me show you the EKS infrastructure that was created with eksctl and how the automated deployment works."

#### Step 1: Show EKS Infrastructure

```bash
# Show EKS cluster created by eksctl
kubectl get nodes -o wide

# Show cluster info
kubectl cluster-info

# Display the eksctl-created resources
eksctl get cluster --name $CLUSTER_NAME --region $AWS_REGION
```

**🎤 Explain eksctl automation:**
> "eksctl automatically created the entire EKS infrastructure including VPC, subnets, security groups, IAM roles, and worker nodes. This demonstrates infrastructure-as-code principles."

#### Step 2: Monitor GitHub Actions Deployment

```bash
# Check deployment status (deployed by GitHub Actions)
kubectl get all -n $NAMESPACE

# Show deployment history
kubectl rollout history deployment/webapp-deployment -n $NAMESPACE

# Show automated resource creation
kubectl describe deployment webapp-deployment -n $NAMESPACE
```

#### Step 3: Verify Automated Configuration

**🌐 Browser Demo:**
- Return to GitHub Actions workflow
- Show completed deployment steps
- Highlight automated kubectl apply commands in logs

```bash
# Show resources created by GitHub Actions
kubectl get all -n $NAMESPACE

# Show persistent volume (automatically bound)
kubectl get pv
kubectl get pvc -n $NAMESPACE

# Show application logs from automated deployment
kubectl logs -l app=webapp -n $NAMESPACE --tail=10
```

**🎤 Key Points:**
> "Notice that GitHub Actions automatically deployed all Kubernetes resources, configured the database, and set up persistent storage. This shows complete deployment automation."

### Part 5: External Access via LoadBalancer (3 minutes)

**🎤 Narration:**
> "Now let's access our application from the internet using AWS LoadBalancer service."

```bash
# Check service status
kubectl get svc webapp-service -n $NAMESPACE

# Get LoadBalancer URL (may take 2-3 minutes)
echo "Waiting for LoadBalancer to provision..."
kubectl get svc webapp-service -n $NAMESPACE -w
# Press Ctrl+C when EXTERNAL-IP appears

# Get the external URL
EXTERNAL_URL=$(kubectl get svc webapp-service -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
echo "Application URL: http://$EXTERNAL_URL"
```

**🌐 Browser Demo:**
- Open the LoadBalancer URL in browser
- Demonstrate full employee management functionality:
  - Add a new employee
  - Retrieve employee information  
  - Show the current background image from S3

### Part 6: S3 Background Image Integration (5 minutes)

**🎤 Narration:**
> "One unique feature is dynamic background image loading from AWS S3. Let me demonstrate changing the background image."

#### Show Current S3 Setup

```bash
# Show S3 bucket contents
aws s3 ls s3://$S3_BUCKET/background-images/ --human-readable

# Show current ConfigMap setting
kubectl get configmap webapp-config -n $NAMESPACE -o yaml
```

#### Change Background Image

```bash
# List available background images
echo "Available background images:"
aws s3 ls s3://$S3_BUCKET/background-images/ --recursive | grep ".jpg"

# Update ConfigMap to use different background
kubectl patch configmap webapp-config -n $NAMESPACE --type merge -p '{
  "data": {
    "BACKGROUND_IMAGE_URL": "https://s3.'$AWS_REGION'.amazonaws.com/'$S3_BUCKET'/background-images/blue-theme.jpg"
  }
}'

# Restart deployment to pick up new config
kubectl rollout restart deployment/webapp-deployment -n $NAMESPACE

# Wait for rollout to complete
kubectl rollout status deployment/webapp-deployment -n $NAMESPACE
```

**🌐 Browser Demo:**
- Refresh the application in browser
- Show the new background image has loaded
- Explain how this demonstrates S3 integration and ConfigMap updates

### Part 7: Data Persistence Demonstration (5 minutes)

**🎤 Narration:**
> "Now I'll demonstrate data persistence by deleting the MySQL pod and showing that data survives."

#### Add Test Data

**🌐 Browser:**
- Add 2-3 employees through the web interface
- Note the employee IDs

#### Delete MySQL Pod

```bash
# Show current pods
kubectl get pods -n $NAMESPACE

# Add employees through web interface first, then:
# Delete the MySQL pod to test persistence
kubectl delete pod -l app=mysql -n $NAMESPACE

# Watch new pod being created
kubectl get pods -n $NAMESPACE -w
# Press Ctrl+C when new MySQL pod is Running

# Verify deployment status
kubectl get pods -n $NAMESPACE
```

#### Verify Data Persistence

**🌐 Browser:**
- Refresh the application
- Use "Get Employee" to retrieve previously added employees
- Show that data persisted despite pod deletion

**🎤 Narration:**
> "As you can see, the employee data persisted even after deleting the MySQL pod. This demonstrates proper use of PersistentVolumeClaims in Kubernetes."

### Part 8: GitHub Actions Pipeline Results (2 minutes)

**🎤 Narration:**
> "Let's check on our GitHub Actions pipeline that we triggered earlier."

**🌐 Browser Demo:**
- Return to GitHub Actions tab
- Show completed workflow
- Highlight successful stages:
  - ✅ Tests passed
  - ✅ Docker build successful  
  - ✅ Security scan clean
  - ✅ ECR push completed
  - ✅ Deployment successful

### Part 9: Additional Background Image Demo (3 minutes)

**🎤 Narration:**
> "Let me quickly demonstrate one more background change to show the flexibility of the S3 integration."

```bash
# Change to another background
kubectl patch configmap webapp-config -n $NAMESPACE --type merge -p '{
  "data": {
    "BACKGROUND_IMAGE_URL": "https://s3.'$AWS_REGION'.amazonaws.com/'$S3_BUCKET'/background-images/professional-bg.jpg"
  }
}'

# Quick restart
kubectl rollout restart deployment/webapp-deployment -n $NAMESPACE --timeout=60s
```

**🌐 Browser:**
- Show the third background image
- Demonstrate that the application remains functional

## Demo Wrap-up (2 minutes)

**🎤 Closing Narration:**
> "To summarize, this CLO835 Final Project demonstrates:
> 
> ✅ **Containerization** - Docker multi-stage builds with security best practices
> ✅ **CI/CD Pipeline** - Automated GitHub Actions workflow  
> ✅ **EKS Deployment** - Production-grade Kubernetes orchestration
> ✅ **Data Persistence** - PVC/PV for stateful applications
> ✅ **External Access** - LoadBalancer for internet connectivity
> ✅ **AWS Integration** - S3 for dynamic content and ECR for image registry
> ✅ **Configuration Management** - ConfigMaps for environment-specific settings
> 
> The application is now running on AWS EKS with complete CI/CD automation, demonstrating cloud-native development practices and production deployment strategies."

## Timing Checklist

- [ ] **0-2 min**: Project introduction
- [ ] **2-5 min**: Local Docker demo  
- [ ] **5-11 min**: GitHub Actions CI/CD pipeline (live deployment)
- [ ] **11-17 min**: EKS infrastructure & automated deployment
- [ ] **17-20 min**: External access demo
- [ ] **20-25 min**: S3 background integration
- [ ] **25-30 min**: Data persistence + automation results
- [ ] **30 min**: Demo complete

## Emergency Recovery Commands

If something goes wrong during demo:

```bash
# Quick pod restart
kubectl delete pods -l app=webapp -n $NAMESPACE

# Reset ConfigMap to default
kubectl patch configmap webapp-config -n $NAMESPACE --type merge -p '{
  "data": {
    "BACKGROUND_IMAGE_URL": "https://s3.'$AWS_REGION'.amazonaws.com/'$S3_BUCKET'/background-images/default-bg.jpg"
  }
}'

# Check service status quickly
kubectl get svc webapp-service -n $NAMESPACE -o wide

# Get logs if app not responding
kubectl logs -l app=webapp -n $NAMESPACE --tail=20
```

---

🎬 **Demo Complete!** 

**Next Step**: Proceed to `scripts/03-demo-cleanup/` for thorough resource cleanup.