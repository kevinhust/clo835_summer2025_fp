# CLO835 Final Project - Flask Employee Management Application

[![CI/CD Pipeline](https://github.com/your-username/clo835_summer2025_fp/workflows/CI/CD%20Pipeline/badge.svg)](https://github.com/your-username/clo835_summer2025_fp/actions)

A containerized Flask web application with MySQL database integration and AWS S3 support, deployed on Amazon EKS with a complete CI/CD pipeline.

## 🏗️ Architecture Overview

- **Frontend**: Flask web application with HTML templates
- **Backend**: Python Flask with PyMySQL database connectivity
- **Database**: MySQL running in Kubernetes
- **Storage**: AWS S3 for static assets (background images)
- **Container Platform**: Docker with multi-stage builds
- **Orchestration**: Kubernetes (Amazon EKS)
- **CI/CD**: GitHub Actions with AWS ECR integration
- **Security**: Trivy vulnerability scanning, non-root containers

## 🚀 Features

- Employee database management (Create, Read operations)
- Dynamic UI theming with color customization
- AWS S3 integration for background images
- Kubernetes-native deployment with persistent storage
- Automated CI/CD pipeline with testing and security scanning
- Multi-environment support (dev, staging, production)
- Health checks and monitoring

## 📋 Prerequisites

### For Local Development
- Python 3.9+
- Docker and Docker Compose
- kubectl
- AWS CLI configured

### For CI/CD Pipeline
- GitHub repository
- AWS Account with EKS cluster
- ECR repository
- Required GitHub Secrets (see Configuration section)

## 🔧 Configuration

### Required GitHub Secrets

Configure the following secrets in your GitHub repository (`Settings > Secrets and variables > Actions`):

```bash
AWS_ACCESS_KEY_ID          # AWS access key for ECR and EKS access
AWS_SECRET_ACCESS_KEY      # AWS secret key
AWS_REGION                 # AWS region (e.g., us-east-1)
ECR_REPOSITORY_URI         # Full ECR repository URI
EKS_CLUSTER_NAME          # Name of your EKS cluster
```

### Environment Variables

The application supports the following environment variables:

```bash
# Database Configuration
DBHOST=localhost              # MySQL host
DBUSER=root                   # MySQL username
DBPWD=password               # MySQL password
DATABASE=employees           # Database name
DBPORT=3306                  # MySQL port

# Application Configuration
APP_COLOR=lime               # UI theme color
GROUP_NAME="Your Group"      # Display name
GROUP_SLOGAN="Your Slogan"   # Display slogan

# AWS Configuration
AWS_ACCESS_KEY_ID=your_key
AWS_SECRET_ACCESS_KEY=your_secret
AWS_REGION=us-east-1
BACKGROUND_IMAGE_URL=s3://your-bucket/image.jpg
```

## 🏃‍♂️ Quick Start

### Local Development

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/clo835_summer2025_fp.git
   cd clo835_summer2025_fp
   ```

2. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

3. **Set environment variables**
   ```bash
   export DBHOST=localhost
   export DBUSER=root
   export DBPWD=password
   export DATABASE=employees
   export DBPORT=3306
   ```

4. **Run the application**
   ```bash
   python app.py
   ```

5. **Access the application**
   - Open http://localhost:81

### Docker Development

1. **Build the Docker image**
   ```bash
   docker build -t webapp:latest .
   ```

2. **Run with Docker Compose** (if you have docker-compose.yml)
   ```bash
   docker-compose up -d
   ```

### Kubernetes Deployment

1. **Apply Kubernetes manifests**
   ```bash
   kubectl apply -f k8s-manifests/
   ```

2. **Check deployment status**
   ```bash
   kubectl get pods -n clo835
   kubectl get services -n clo835
   ```

3. **Access the application**
   ```bash
   kubectl port-forward svc/webapp-service 8080:80 -n clo835
   ```

## 🔄 CI/CD Pipeline

The GitHub Actions pipeline automatically:

### On Pull Requests:
- ✅ Runs unit tests
- ✅ Performs code linting
- ✅ Builds Docker image
- ✅ Scans for vulnerabilities
- ✅ Validates Kubernetes manifests

### On Main Branch Push:
- ✅ All PR checks
- ✅ Pushes image to ECR
- ✅ Deploys to EKS cluster
- ✅ Runs deployment verification
- ✅ Sends notifications

### Pipeline Stages:

1. **Test and Build**
   - Code checkout
   - Python environment setup
   - Dependency installation
   - Unit test execution
   - Code linting with flake8
   - Docker image build and push to ECR
   - Trivy security scanning

2. **Validate**
   - Kubernetes manifest validation
   - kubeval syntax checking

3. **Deploy** (main branch only)
   - EKS cluster authentication
   - Application deployment
   - Rolling update verification
   - Service endpoint verification

4. **Notify**
   - Pipeline status notifications
   - Deployment confirmation

## 🧪 Testing

### Run Unit Tests
```bash
# Install test dependencies
pip install pytest pytest-flask pytest-mock

# Run tests
python -m pytest tests/ -v

# Run with coverage
python -m pytest tests/ --cov=app --cov-report=html
```

### Test Categories
- **Unit Tests**: Application logic and functions
- **Integration Tests**: Database connectivity (mocked)
- **Route Tests**: Flask endpoint testing
- **S3 Integration Tests**: AWS S3 functionality (mocked)

## 📁 Project Structure

```
clo835_summer2025_fp/
├── .github/
│   └── workflows/
│       └── ci-cd.yml              # GitHub Actions CI/CD pipeline
├── k8s-manifests/                 # Kubernetes deployment files
│   ├── namespace.yaml
│   ├── configmap.yaml
│   ├── secrets.yaml
│   ├── mysql-deployment.yaml
│   ├── mysql-service.yaml
│   ├── webapp-deployment.yaml
│   ├── webapp-service.yaml
│   ├── pvc.yaml
│   └── rbac.yaml
├── templates/                     # Flask HTML templates
│   ├── addemp.html
│   ├── addempoutput.html
│   ├── getemp.html
│   ├── getempoutput.html
│   └── about.html
├── tests/                         # Unit tests
│   ├── __init__.py
│   └── test_app.py
├── app.py                         # Main Flask application
├── requirements.txt               # Python dependencies
├── Dockerfile                     # Multi-stage Docker build
├── mysql.sql                      # Database schema
├── .gitignore                     # Git ignore rules
└── README.md                      # This file
```

## 🔒 Security Features

- **Non-root containers**: Application runs as unprivileged user
- **Vulnerability scanning**: Trivy scans all Docker images
- **Secret management**: No hardcoded credentials
- **Network policies**: Kubernetes network segmentation
- **Image signing**: Optional container image verification
- **RBAC**: Role-based access control in Kubernetes

## 🐛 Troubleshooting

### Common Issues

1. **Pipeline fails on ECR push**
   - Verify AWS credentials in GitHub secrets
   - Check ECR repository exists and permissions

2. **Tests fail in CI**
   - Ensure all test dependencies in requirements.txt
   - Check environment variable mocking

3. **Kubernetes deployment fails**
   - Verify EKS cluster access
   - Check image URI in deployment manifests

4. **Application can't connect to database**
   - Verify MySQL service is running
   - Check database credentials and connectivity

### Debug Commands

```bash
# Check pipeline logs
gh run list
gh run view <run-id>

# Debug Kubernetes
kubectl describe pod <pod-name> -n clo835
kubectl logs <pod-name> -n clo835

# Test Docker image locally
docker run -p 8080:81 <image-name>

# Validate Kubernetes manifests
kubectl --dry-run=client apply -f k8s-manifests/
```

## 📊 Monitoring and Logs

### Application Logs
```bash
kubectl logs -f deployment/webapp -n clo835
```

### Pipeline Monitoring
- GitHub Actions dashboard shows pipeline status
- ECR repositories show image push history
- EKS cluster monitoring via AWS Console

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is part of the CLO835 course and is for educational purposes.

## 📚 Additional Resources

- [Flask Documentation](https://flask.palletsprojects.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

---

🎓 **CLO835 Summer 2025 Final Project** - Container Technology and Cloud Computing