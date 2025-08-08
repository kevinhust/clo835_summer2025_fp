# CLO835 Final Project - Demo Script and Recording Guide

## Table of Contents
1. [Recording Preparation](#recording-preparation)
2. [Demo Script Overview](#demo-script-overview)
3. [Detailed Demo Flow](#detailed-demo-flow)
4. [Technical Checklist](#technical-checklist)
5. [Troubleshooting During Demo](#troubleshooting-during-demo)
6. [Post-Demo Documentation](#post-demo-documentation)

## Recording Preparation

### Pre-Recording Checklist

**Environment Setup:**
- [ ] All infrastructure deployed and running
- [ ] Application accessible via LoadBalancer
- [ ] Background image working correctly
- [ ] Test data prepared for demo
- [ ] Screen recording software ready (OBS, Loom, etc.)
- [ ] Audio quality tested (clear microphone)
- [ ] Browser bookmarks set up for quick access

**AWS Console Access:**
- [ ] AWS Management Console open
- [ ] EKS cluster page bookmarked
- [ ] ECR repository page bookmarked
- [ ] S3 bucket page bookmarked
- [ ] CloudFormation/Terraform state verified

**Local Development Environment:**
- [ ] Terminal windows organized
- [ ] kubectl configured and tested
- [ ] Docker running locally
- [ ] GitHub repository open
- [ ] All necessary commands prepared

**Recording Equipment:**
- [ ] Screen resolution optimized (1920x1080 recommended)
- [ ] Font sizes readable in recording
- [ ] External microphone connected (if available)
- [ ] Quiet environment confirmed
- [ ] Recording software tested

### Time Management

**Total Duration: 30 minutes maximum**

Recommended time allocation:
- Introduction and overview: 2-3 minutes
- Local Docker testing: 4-5 minutes
- GitHub Actions demonstration: 3-4 minutes
- AWS infrastructure tour: 5-6 minutes
- Application deployment and testing: 8-10 minutes
- ConfigMap update demonstration: 5-6 minutes
- Data persistence testing: 3-4 minutes
- Conclusion and summary: 2-3 minutes

## Demo Script Overview

### Script Structure

```
1. Introduction (2-3 min)
   - Project overview
   - Architecture diagram
   - Key technologies

2. Local Development (4-5 min)
   - Docker image build
   - Local testing with docker-compose
   - Application functionality

3. CI/CD Pipeline (3-4 min)
   - GitHub Actions workflow
   - ECR image push
   - Automated testing

4. Infrastructure (5-6 min)
   - EKS cluster overview
   - Terraform infrastructure
   - AWS services integration

5. Application Deployment (8-10 min)
   - Kubernetes resources
   - Application access
   - Functionality testing
   - Background image from S3

6. Configuration Management (5-6 min)
   - ConfigMap update
   - Rolling deployment
   - New background image

7. Data Persistence (3-4 min)
   - Add test data
   - Pod deletion
   - Data verification

8. Conclusion (2-3 min)
   - Summary of achievements
   - Learning outcomes
   - Next steps
```

## Detailed Demo Flow

### 1. Introduction (2-3 minutes)

**Script:**
```
"Welcome to my CLO835 Final Project demonstration. I'm going to showcase a complete 
DevOps implementation that includes containerized application deployment, CI/CD 
pipeline automation, and cloud infrastructure management using AWS services.

The project demonstrates:
- A Flask web application with MySQL database
- Docker containerization and GitHub Actions CI/CD
- Amazon EKS for container orchestration
- Terraform for infrastructure as code
- Integration with S3 for dynamic content and ECR for image storage

Let me start by showing you the architecture overview..."
```

**Actions:**
- Open architecture diagram (docs/ARCHITECTURE.md)
- Highlight key components
- Show GitHub repository structure
- Explain the flow from development to production

### 2. Local Development Testing (4-5 minutes)

**Script:**
```
"First, let me demonstrate the application running locally using Docker to verify 
functionality before cloud deployment."
```

**Actions:**
```bash
# 1. Show Dockerfile
cat Dockerfile

# 2. Build Docker image locally
docker build -t clo835-webapp:local .

# 3. Run application locally (with environment variables)
docker run -d --name clo835-local \
  -p 8081:81 \
  -e DBHOST=localhost \
  -e DBPORT=3306 \
  -e DBUSER=root \
  -e DBPWD=password \
  -e DATABASE=employees \
  -e GROUP_NAME="Demo Group" \
  -e GROUP_SLOGAN="Cloud Native Excellence" \
  clo835-webapp:local

# 4. Test application
curl http://localhost:8081
```

**Demonstration Points:**
- Show application loading in browser
- Navigate through pages (home, about, add employee)
- Explain the application functionality
- Show application logs

### 3. GitHub Actions CI/CD Pipeline (3-4 minutes)

**Script:**
```
"Now let me show you the automated CI/CD pipeline that builds and deploys our 
application whenever code is pushed to the main branch."
```

**Actions:**
1. **Show GitHub Actions workflow:**
   ```bash
   # Open .github/workflows/ci-cd.yml
   cat .github/workflows/ci-cd.yml
   ```

2. **Demonstrate recent workflow run:**
   - Open GitHub repository
   - Navigate to Actions tab
   - Show successful workflow execution
   - Highlight build steps and ECR push

3. **Show ECR repository:**
   - Open AWS ECR console
   - Show pushed images with tags
   - Explain image versioning strategy

**Key Points to Mention:**
- Automatic trigger on code push
- Docker image building and testing
- Push to private ECR repository
- Security scanning integration

### 4. AWS Infrastructure Tour (5-6 minutes)

**Script:**
```
"The infrastructure is completely managed as code using Terraform. Let me show you 
the AWS resources that were automatically created."
```

**Actions:**
1. **Show Terraform configuration:**
   ```bash
   # Navigate to terraform directory
   cd terraform
   
   # Show main configuration
   cat main.tf
   
   # Show current state
   terraform output
   ```

2. **AWS Console tour:**
   - **EKS Cluster:** Show cluster overview, nodes, and configuration
   - **VPC:** Show network topology and subnets
   - **ECR:** Demonstrate private image repository
   - **S3:** Show background image bucket
   - **IAM:** Highlight service roles and policies

3. **Cost consideration:**
   ```bash
   # Show current resource costs
   aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-31 \
     --granularity MONTHLY --metrics BlendedCost
   ```

### 5. Application Deployment and Testing (8-10 minutes)

**Script:**
```
"Now let's deploy the application to the EKS cluster and verify all the required 
functionality."
```

**Actions:**

1. **Show Kubernetes manifests:**
   ```bash
   cd k8s-manifests
   ls -la
   
   # Show key manifests
   cat namespace.yaml
   cat configmap.yaml
   cat webapp-deployment.yaml
   ```

2. **Deploy application:**
   ```bash
   # Deploy all manifests
   ./deploy.sh
   
   # Or show individual deployment
   kubectl apply -f namespace.yaml
   kubectl apply -f configmap.yaml
   kubectl apply -f secrets.yaml
   kubectl apply -f pvc.yaml
   kubectl apply -f mysql-deployment.yaml
   kubectl apply -f mysql-service.yaml
   kubectl apply -f webapp-deployment.yaml
   kubectl apply -f webapp-service.yaml
   ```

3. **Verify deployment:**
   ```bash
   # Check all resources
   kubectl get all -n clo835
   
   # Check pod status
   kubectl get pods -n clo835 -o wide
   
   # Check services
   kubectl get svc -n clo835
   
   # Get LoadBalancer URL
   kubectl get svc webapp-service -n clo835
   ```

4. **Test application functionality:**
   - Open application in browser using LoadBalancer URL
   - Show background image loading from S3
   - Add a test employee record
   - Retrieve employee information
   - Show application logs

5. **Verify S3 integration:**
   ```bash
   # Check application logs for S3 integration
   kubectl logs -l app=webapp -n clo835 | grep -i s3
   kubectl logs -l app=webapp -n clo835 | grep "Background image"
   ```

### 6. ConfigMap Update Demonstration (5-6 minutes)

**Script:**
```
"One of the key requirements is to demonstrate updating the background image URL 
through ConfigMap and showing the new image in the browser."
```

**Actions:**

1. **Show current ConfigMap:**
   ```bash
   kubectl get configmap webapp-config -n clo835 -o yaml
   ```

2. **Upload new background image to S3:**
   ```bash
   # Upload new image
   aws s3 cp new-background.jpg s3://your-bucket-name/new-background.jpg
   
   # Verify upload
   aws s3 ls s3://your-bucket-name/
   ```

3. **Update ConfigMap:**
   ```bash
   # Edit ConfigMap to point to new image
   kubectl edit configmap webapp-config -n clo835
   
   # Or apply updated configmap file
   kubectl apply -f configmap-updated.yaml
   ```

4. **Restart application pods:**
   ```bash
   # Rolling restart to pick up new configuration
   kubectl rollout restart deployment/webapp-deployment -n clo835
   
   # Watch rollout status
   kubectl rollout status deployment/webapp-deployment -n clo835
   ```

5. **Verify new background image:**
   - Refresh browser
   - Show new background image
   - Check application logs for new image URL
   ```bash
   kubectl logs -l app=webapp -n clo835 | tail -20
   ```

### 7. Data Persistence Testing (3-4 minutes)

**Script:**
```
"Let me demonstrate data persistence by adding data, deleting the MySQL pod, 
and verifying the data survives the pod restart."
```

**Actions:**

1. **Add test data:**
   - Use web interface to add employee record
   - Record the employee details for verification

2. **Show current MySQL pod:**
   ```bash
   kubectl get pods -l app=mysql -n clo835
   ```

3. **Delete MySQL pod:**
   ```bash
   # Delete the MySQL pod
   kubectl delete pod -l app=mysql -n clo835
   
   # Watch new pod creation
   kubectl get pods -l app=mysql -n clo835 -w
   ```

4. **Verify data persistence:**
   ```bash
   # Wait for pod to be ready
   kubectl wait --for=condition=ready pods -l app=mysql -n clo835 --timeout=120s
   
   # Check pod status
   kubectl get pods -l app=mysql -n clo835
   ```

5. **Test data retrieval:**
   - Use web interface to retrieve the employee data
   - Show that data persisted through pod restart
   - Verify PVC and PV status:
   ```bash
   kubectl get pvc,pv -n clo835
   ```

### 8. Conclusion and Summary (2-3 minutes)

**Script:**
```
"This demonstration showcased a complete DevOps implementation meeting all 
CLO835 Final Project requirements:

✓ Enhanced Flask application with configurable background images
✓ Automated CI/CD pipeline with GitHub Actions and ECR
✓ Complete EKS deployment with proper networking and security
✓ Data persistence with EBS volumes
✓ ConfigMap-driven configuration management
✓ Integration with private S3 bucket for dynamic content

The project demonstrates modern cloud-native development practices, infrastructure 
as code, and container orchestration using industry-standard tools and AWS services."
```

**Final Actions:**
- Show final application state
- Highlight key achievements
- Mention cost considerations and cleanup procedures

## Technical Checklist

### Pre-Demo Technical Verification

**Infrastructure Status:**
- [ ] EKS cluster healthy and accessible
- [ ] All worker nodes in Ready state
- [ ] LoadBalancer service has external IP
- [ ] ECR repository contains latest image
- [ ] S3 bucket accessible with proper permissions

**Application Status:**
- [ ] All pods running and ready
- [ ] Database connection working
- [ ] Background image loading correctly
- [ ] ConfigMap and secrets properly configured
- [ ] RBAC permissions working

**Network Connectivity:**
- [ ] Application accessible from internet
- [ ] Internal service communication working
- [ ] DNS resolution functioning
- [ ] Security groups properly configured

**Backup Preparation:**
- [ ] Secondary S3 images ready for ConfigMap demo
- [ ] kubectl commands tested and working
- [ ] Browser bookmarks and tabs prepared
- [ ] Terminal windows organized

### During Demo Monitoring

**Performance Indicators:**
- Monitor pod resource usage
- Watch for any pod restarts or failures
- Check LoadBalancer health status
- Verify S3 access logs

**Backup Plans:**
- Have port-forward command ready if LoadBalancer fails
- Prepare kubectl proxy for alternative access
- Keep AWS console open for quick troubleshooting
- Have demo data prepared as fallback

## Troubleshooting During Demo

### Common Issues and Quick Fixes

**1. LoadBalancer Not Accessible:**
```bash
# Quick fix: Use port-forward
kubectl port-forward svc/webapp-service 8080:80 -n clo835

# Alternative: Check security groups
aws ec2 describe-security-groups --group-ids <sg-id>
```

**2. Pods Not Starting:**
```bash
# Quick diagnosis
kubectl describe pod <pod-name> -n clo835
kubectl get events -n clo835 --sort-by='.lastTimestamp'

# Quick fix: Restart deployment
kubectl rollout restart deployment/webapp-deployment -n clo835
```

**3. S3 Access Issues:**
```bash
# Check IAM permissions
kubectl logs -l app=webapp -n clo835 | grep -i error

# Verify secret
kubectl get secret aws-secret -n clo835 -o yaml
```

**4. Database Connection Issues:**
```bash
# Check MySQL status
kubectl logs -l app=mysql -n clo835

# Test connectivity
kubectl exec -it deploy/webapp-deployment -n clo835 -- nc -zv mysql-service 3306
```

### Recovery Strategies

**If Major Issues Occur:**
1. Stay calm and explain the issue to audience
2. Use pre-prepared screenshots as backup
3. Switch to alternative access method (port-forward)
4. Continue with other demonstration parts
5. Address issue in Q&A if time permits

**Time Management:**
- If running behind, prioritize core requirements
- Skip optional deep-dives if necessary
- Focus on key functionality demonstrations
- Save detailed explanations for Q&A

## Post-Demo Documentation

### Screenshot Collection

**Required Screenshots:**
- [ ] Application homepage with background image
- [ ] Add employee form and success page
- [ ] Get employee form and results
- [ ] Kubernetes resources (kubectl get all)
- [ ] AWS EKS cluster overview
- [ ] ECR repository with images
- [ ] S3 bucket with background images
- [ ] GitHub Actions successful workflow
- [ ] ConfigMap before and after update
- [ ] Application with new background image
- [ ] Data persistence verification

### Evidence Collection

**Logs and Outputs:**
```bash
# Collect application logs
kubectl logs -l app=webapp -n clo835 > webapp-logs.txt

# Collect MySQL logs
kubectl logs -l app=mysql -n clo835 > mysql-logs.txt

# Collect Kubernetes events
kubectl get events -n clo835 > k8s-events.txt

# Collect resource status
kubectl get all -n clo835 -o wide > k8s-resources.txt

# Collect Terraform outputs
cd terraform && terraform output > terraform-outputs.txt
```

### Demo Metrics

**Performance Data:**
```bash
# Resource utilization
kubectl top nodes
kubectl top pods -n clo835

# Service endpoints
kubectl get endpoints -n clo835

# Storage usage
kubectl get pvc -n clo835
```

### Final Validation

**Post-Demo Checklist:**
- [ ] All required functionality demonstrated
- [ ] Screenshots and evidence collected
- [ ] Recording quality verified
- [ ] Documentation updated with any discoveries
- [ ] Issues log created for future reference
- [ ] Resource cleanup scheduled

---

**Note:** This demo script provides a comprehensive framework for showcasing the CLO835 Final Project. Adapt the timing and content based on your specific implementation and any unique challenges encountered during development.