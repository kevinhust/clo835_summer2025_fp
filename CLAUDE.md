# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a CLO835 Final Project - a containerized Flask employee management application with MySQL database, deployed on Amazon EKS with AWS S3 integration. It demonstrates cloud-native application development, DevOps practices, and complete CI/CD pipeline implementation.

## Essential Commands

### Local Development
```bash
# Install dependencies
pip install -r requirements.txt

# Run the application locally
python app.py

# Run tests
python -m pytest tests/ -v
python -m pytest tests/ --cov=app --cov-report=html

# Build Docker image
docker build -t webapp:latest .

# Run Docker container
docker run -p 8080:81 webapp:latest
```

### Kubernetes Operations
```bash
# Deploy entire application
./k8s-manifests/deploy.sh

# Deploy using convenience script
./scripts/deploy-complete.sh

# Test functionality after deployment
./scripts/test-functionality.sh

# Validate all prerequisites
./scripts/validate-prerequisites.sh

# View application logs
kubectl logs -f deployment/webapp-deployment -n clo835

# Check deployment status
kubectl get all -n clo835

# Port forward for local testing
kubectl port-forward svc/webapp-service 8080:80 -n clo835

# Clean up resources
./k8s-manifests/cleanup.sh
./scripts/cleanup-all.sh
```

### Terraform Infrastructure
```bash
# Deploy AWS infrastructure
cd terraform
terraform init
terraform plan
terraform apply

# Update kubeconfig for EKS
aws eks update-kubeconfig --region us-east-1 --name clo835-final-project

# Destroy infrastructure
terraform destroy
```

## Architecture Overview

### Core Components
- **Flask Application** (`app.py`): Main web application with employee management
- **MySQL Database**: Persistent storage running in Kubernetes with PVC
- **AWS S3 Integration**: Dynamic background image loading from S3 buckets
- **Multi-stage Dockerfile**: Optimized production container with non-root user
- **EKS Cluster**: Managed Kubernetes environment via Terraform

### Key Configuration Files
- `k8s-manifests/`: Complete Kubernetes deployment manifests
- `terraform/`: AWS infrastructure as code (VPC, EKS, ECR, IAM)
- `requirements.txt`: Python dependencies including Flask, PyMySQL, boto3
- `pytest.ini`: Test configuration with markers for unit/integration/aws tests

### CI/CD Pipeline
The GitHub Actions workflow (`/.github/workflows/ci-cd.yml`) handles:
- Code testing and linting with flake8
- Docker image building and ECR push
- Trivy vulnerability scanning
- Kubernetes manifest validation
- EKS deployment automation
- Post-deployment testing

### Environment Configuration
Application uses environment variables for configuration:
- Database: `DBHOST`, `DBUSER`, `DBPWD`, `DATABASE`, `DBPORT`
- AWS: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_REGION`
- App: `APP_COLOR`, `GROUP_NAME`, `GROUP_SLOGAN`, `BACKGROUND_IMAGE_URL`

### Security Features
- Non-root container execution (`appuser`)
- Kubernetes RBAC with minimal permissions
- Secrets management for sensitive data
- Network policies and resource limits
- Automated vulnerability scanning

## Development Workflow

### Local Testing
1. Set required environment variables for database connection
2. Run application locally: `python app.py` (listens on port 81)
3. Run unit tests: `python -m pytest tests/ -v`
4. Test Docker build: `docker build -t webapp:latest .`

### Kubernetes Development
1. Use `kubectl apply -f k8s-manifests/` for incremental updates
2. Update ConfigMap for configuration changes without rebuilding
3. Use `kubectl rollout restart deployment/webapp-deployment -n clo835` to apply config changes
4. Monitor with `kubectl logs -f deployment/webapp-deployment -n clo835`

### Key Configuration Points
- **Image URI**: Update `YOUR_ECR_URI` in `k8s-manifests/webapp-deployment.yaml` with actual ECR repository
- **Terraform Variables**: Configure `terraform/terraform.tfvars` with your AWS settings
- **GitHub Secrets**: Set AWS credentials and repository details for CI/CD

### Testing Strategy
- Unit tests focus on application logic and mocked dependencies
- Integration tests verify database connectivity and S3 functionality  
- Deployment tests validate Kubernetes resources and service endpoints
- Manual testing checklist included in `scripts/test-functionality.sh`

## Important Notes

- The application runs on port 81 inside containers (Flask default override)
- MySQL requires initialization with the schema from `mysql.sql`
- S3 integration is optional - application gracefully handles missing AWS credentials
- LoadBalancer service may take several minutes to provision external IP
- Persistent volumes ensure data survives pod restarts
- Background images are downloaded from S3 and cached in container filesystem