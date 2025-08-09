# CLO835 Final Project

A containerized Flask employee management application with MySQL database, deployed on Amazon EKS with AWS S3 integration. This project demonstrates cloud-native application development, DevOps practices, and complete CI/CD pipeline implementation.

## 🚀 Quick Start

### 1. Prerequisites
- AWS CLI configured with appropriate permissions
- `kubectl` installed
- `eksctl` installed
- Docker installed (for local testing)

### 2. Infrastructure Setup
```bash
# Create all AWS resources (S3, ECR, EKS cluster)
./scripts/create-infrastructure.sh
```

### 3. Deploy Application
```bash
# Deploy using Kubernetes manifests
kubectl apply -f k8s-manifests/

# Or push code to trigger GitHub Actions deployment
git push origin main
```

### 4. Access Application
```bash
# Get LoadBalancer URL
kubectl get svc webapp-service -n fp

# Or use port forwarding for testing
kubectl port-forward svc/webapp-service 8080:80 -n fp
```

## 📋 Project Requirements (CLO835)

✅ **Enhanced Flask Application**
- Background images from private S3 bucket
- MySQL database integration with K8s secrets
- Port 81 configuration
- Group name and slogan via ConfigMap
- Logging of background image URL

✅ **GitHub Actions CI/CD**
- Automated Docker builds and ECR push
- Unit testing and linting
- Kubernetes deployment to EKS
- Security scanning with Trivy

✅ **EKS Infrastructure**
- 2 worker nodes using eksctl
- Namespace "fp"
- Service account "clo835_sa" with RBAC

✅ **Kubernetes Resources**
- ConfigMap for application settings
- Secrets for MySQL and AWS credentials
- PersistentVolumeClaim (3Gi, gp2, ReadWriteOnce)
- MySQL deployment with persistent storage
- Flask app deployment from ECR
- LoadBalancer service for external access

## 🏗️ Architecture

```
GitHub → GitHub Actions → Amazon ECR → Amazon EKS
                                           ↓
                                      Namespace: fp
                                     ┌─────────────┐
                                     │ Flask App   │
                                     │ (port 81)   │
                                     └─────────────┘
                                           │
                                     ┌─────────────┐
                                     │   MySQL     │
                                     │ (with PVC)  │
                                     └─────────────┘
                                           │
                                    ┌─────────────────┐
                                    │ AWS S3 Bucket   │
                                    │ (bg images)     │
                                    └─────────────────┘
```

## 🔧 Development

### Local Testing
```bash
# Run application locally
pip install -r requirements.txt
python app.py

# Run tests
python -m pytest tests/ -v

# Test Docker build
docker build -t webapp:latest .
docker run -p 8080:81 webapp:latest
```

### GitHub Actions Setup
Set these secrets in your GitHub repository:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

## 📁 Project Structure

```
├── app.py                          # Flask application
├── Dockerfile                      # Multi-stage container build
├── requirements.txt                # Python dependencies
├── mysql.sql                       # Database schema
├── eks-cluster.yaml               # EKS cluster configuration
├── .github/workflows/ci-cd.yml    # CI/CD pipeline
├── k8s-manifests/                 # Kubernetes resources
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secrets.yaml
│   ├── mysql-pvc.yaml
│   ├── mysql-deployment.yaml
│   ├── webapp-deployment.yaml
│   └── services.yaml
├── scripts/
│   ├── create-infrastructure.sh   # Setup AWS resources
│   └── cleanup-infrastructure.sh  # Cleanup resources
└── templates/                     # HTML templates
    ├── addemp.html
    ├── getemp.html
    └── ...
```

## 🧪 Testing

The project includes comprehensive testing:
- **Unit Tests**: Application logic with mocked dependencies
- **Integration Tests**: Database and S3 connectivity
- **GitHub Actions**: Automated testing on every push
- **Security Scanning**: Trivy vulnerability scanning

```bash
# Run all tests
python -m pytest tests/ -v

# Run with coverage
python -m pytest tests/ --cov=app --cov-report=html
```

## 🔒 Security Features

- Non-root container execution (`appuser`)
- Kubernetes RBAC with minimal permissions
- Secrets management for sensitive data
- Private S3 bucket with blocked public access
- ECR image vulnerability scanning
- Network policies and resource limits

## 🛠️ Key Commands

### Infrastructure Management
```bash
# Create infrastructure
./scripts/create-infrastructure.sh

# Delete everything
./scripts/cleanup-infrastructure.sh

# Manual cluster creation
eksctl create cluster -f eks-cluster.yaml

# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name clo835-eks-cluster
```

### Kubernetes Operations
```bash
# Deploy application
kubectl apply -f k8s-manifests/

# Check status
kubectl get all -n fp

# View logs
kubectl logs -f deployment/webapp-deployment -n fp

# Restart deployment
kubectl rollout restart deployment/webapp-deployment -n fp
```

## 📖 Assignment Compliance

This project fully implements all CLO835 Final Project requirements:

1. ✅ Enhanced web application with S3 background images
2. ✅ GitHub Actions for automated build and deployment
3. ✅ EKS cluster with 2 worker nodes and "fp" namespace
4. ✅ Complete K8s manifests (ConfigMap, Secrets, PVC, RBAC, Deployments, Services)
5. ✅ MySQL with persistent storage
6. ✅ LoadBalancer service for external access
7. ✅ Background image updates via ConfigMap changes

## 🆘 Troubleshooting

### Common Issues

1. **EKS cluster not accessible**
   ```bash
   aws eks update-kubeconfig --region us-east-1 --name clo835-eks-cluster
   ```

2. **LoadBalancer pending**
   ```bash
   # Check AWS Load Balancer Controller installation
   kubectl get pods -n kube-system | grep aws-load-balancer
   ```

3. **Application can't access S3**
   - Verify AWS credentials in secrets
   - Check S3 bucket exists and has proper permissions
   - Review application logs for S3 errors

4. **MySQL connection issues**
   - Verify MySQL pod is running: `kubectl get pods -n fp`
   - Check database credentials in secrets
   - Ensure PVC is bound: `kubectl get pvc -n fp`

### Getting Help

For more detailed troubleshooting, check:
- Application logs: `kubectl logs -f deployment/webapp-deployment -n fp`
- MySQL logs: `kubectl logs -f deployment/mysql-deployment -n fp`
- GitHub Actions logs in the Actions tab

## 🏆 Project Highlights

- **Simplified Architecture**: No Terraform needed - uses eksctl and AWS CLI
- **Production Ready**: Includes health checks, security scanning, and RBAC
- **Full Automation**: One-command infrastructure setup and deployment
- **Best Practices**: Follows K8s and AWS security best practices
- **Educational**: Clear structure for learning cloud-native development

---

**Note**: This project is designed for educational purposes as part of CLO835 coursework. All resources should be cleaned up after evaluation to avoid AWS charges.