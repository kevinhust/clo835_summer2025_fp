# CLO835 Final Project - Architecture Documentation

## Table of Contents
1. [System Overview](#system-overview)
2. [Component Architecture](#component-architecture)
3. [Network Architecture](#network-architecture)
4. [Security Architecture](#security-architecture)
5. [Data Flow](#data-flow)
6. [Infrastructure Components](#infrastructure-components)
7. [Deployment Architecture](#deployment-architecture)
8. [Monitoring and Observability](#monitoring-and-observability)

## System Overview

The CLO835 Final Project implements a comprehensive cloud-native application demonstrating modern DevOps practices, containerization, and cloud infrastructure management.

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                          Internet Users                         │
└─────────────────────┬───────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│                    AWS Application Load Balancer                │
└─────────────────────┬───────────────────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────────────────┐
│                        Amazon EKS Cluster                       │
│  ┌─────────────────┬─────────────────┬─────────────────────────┐ │
│  │   Worker Node 1 │   Worker Node 2 │      Control Plane      │ │
│  │                 │                 │    (AWS Managed)        │ │
│  └─────────────────┴─────────────────┴─────────────────────────┘ │
└─────────────────────┬───────────────────────────────────────────┘
                      │
    ┌─────────────────┼─────────────────┐
    │                 │                 │
┌───▼───┐     ┌──────▼──────┐     ┌───▼────┐
│  ECR  │     │  S3 Bucket  │     │   EBS  │
│Images │     │ Background  │     │Volumes │
│       │     │   Images    │     │        │
└───────┘     └─────────────┘     └────────┘
```

### Architecture Principles

1. **Cloud-Native Design**: Built for cloud environments with container orchestration
2. **Microservices Pattern**: Separation of concerns between web and database tiers
3. **Infrastructure as Code**: All infrastructure defined and version-controlled
4. **CI/CD Integration**: Automated build, test, and deployment pipeline
5. **Security by Design**: Multiple layers of security controls
6. **Scalability**: Horizontal scaling capabilities for both web and data tiers
7. **Observability**: Comprehensive logging and monitoring

## Component Architecture

### Application Layer

```
┌─────────────────────────────────────────────────────────────┐
│                    Flask Web Application                    │
├─────────────────────────────────────────────────────────────┤
│  Features:                                                  │
│  • Employee Management (CRUD Operations)                   │
│  • Dynamic Background Images from S3                       │
│  • Configuration via Environment Variables                 │
│  • Database Connection Pooling                             │
│  • Logging and Health Checks                               │
├─────────────────────────────────────────────────────────────┤
│  Technology Stack:                                          │
│  • Python 3.9+                                             │
│  • Flask Framework                                          │
│  • PyMySQL for Database Connectivity                       │
│  • Boto3 for AWS SDK                                       │
│  • Gunicorn WSGI Server                                     │
└─────────────────────────────────────────────────────────────┘
```

### Database Layer

```
┌─────────────────────────────────────────────────────────────┐
│                      MySQL Database                         │
├─────────────────────────────────────────────────────────────┤
│  Features:                                                  │
│  • Employee table with CRUD operations                     │
│  • Persistent storage via EBS volumes                      │
│  • Automated backups via EBS snapshots                     │
│  • Connection pooling and optimization                     │
├─────────────────────────────────────────────────────────────┤
│  Configuration:                                             │
│  • MySQL 8.0                                               │
│  • 3Gi persistent volume                                    │
│  • ReadWriteOnce access mode                               │
│  • gp2 storage class                                       │
└─────────────────────────────────────────────────────────────┘
```

### Storage Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Storage Components                     │
├─────────────────────────────────────────────────────────────┤
│  Amazon S3 (Background Images):                            │
│  • Private bucket with IAM-based access                    │
│  • Versioning enabled                                      │
│  • Server-side encryption                                  │
│  • Lifecycle policies for cost optimization                │
├─────────────────────────────────────────────────────────────┤
│  Amazon EBS (Database Storage):                            │
│  • gp2 volumes for MySQL data                              │
│  • 3Gi capacity with auto-scaling potential               │
│  • Automatic backups via snapshots                        │
│  • Encryption at rest                                      │
├─────────────────────────────────────────────────────────────┤
│  Amazon ECR (Container Images):                            │
│  • Private repository for application images               │
│  • Image vulnerability scanning                            │
│  • Lifecycle policies for image management                 │
│  • Integration with GitHub Actions                         │
└─────────────────────────────────────────────────────────────┘
```

## Network Architecture

### VPC and Networking

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS VPC (10.0.0.0/16)              │
├─────────────────────────────────────────────────────────────┤
│  Public Subnets (10.0.1.0/24, 10.0.2.0/24):              │
│  • Application Load Balancer                               │
│  • NAT Gateways                                            │
│  • Bastion hosts (if needed)                               │
├─────────────────────────────────────────────────────────────┤
│  Private Subnets (10.0.3.0/24, 10.0.4.0/24):             │
│  • EKS Worker Nodes                                        │
│  • Application Pods                                        │
│  • Database Pods                                           │
├─────────────────────────────────────────────────────────────┤
│  Network Components:                                       │
│  • Internet Gateway                                        │
│  • NAT Gateways (Multi-AZ)                                │
│  • Route Tables                                            │
│  • Security Groups                                         │
│  • Network ACLs                                            │
└─────────────────────────────────────────────────────────────┘
```

### Kubernetes Networking

```
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes Networking                    │
├─────────────────────────────────────────────────────────────┤
│  CNI Plugin: AWS VPC CNI                                   │
│  • Pod IPs from VPC CIDR                                   │
│  • Native VPC networking                                   │
│  • Security group enforcement                              │
├─────────────────────────────────────────────────────────────┤
│  Service Types:                                             │
│  • ClusterIP: mysql-service (internal only)               │
│  • LoadBalancer: webapp-service (external access)         │
├─────────────────────────────────────────────────────────────┤
│  Ingress/Load Balancing:                                   │
│  • AWS Load Balancer Controller                            │
│  • Application Load Balancer (ALB)                         │
│  • Target Group health checks                              │
└─────────────────────────────────────────────────────────────┘
```

## Security Architecture

### Identity and Access Management

```
┌─────────────────────────────────────────────────────────────┐
│                         IAM Structure                       │
├─────────────────────────────────────────────────────────────┤
│  EKS Cluster Service Role:                                  │
│  • AmazonEKSClusterPolicy                                  │
│  • AmazonEKSVPCResourceController                          │
├─────────────────────────────────────────────────────────────┤
│  EKS Node Group Role:                                       │
│  • AmazonEKSWorkerNodePolicy                               │
│  • AmazonEKS_CNI_Policy                                    │
│  • AmazonEC2ContainerRegistryReadOnly                      │
├─────────────────────────────────────────────────────────────┤
│  Application Service Account:                               │
│  • S3 read access for background images                    │
│  • ECR image pull permissions                              │
│  • CloudWatch logs permissions                             │
└─────────────────────────────────────────────────────────────┘
```

### Kubernetes RBAC

```
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes RBAC Model                    │
├─────────────────────────────────────────────────────────────┤
│  ServiceAccount: clo835-sa                                 │
│  • Namespace: clo835                                       │
│  • Limited permissions scope                               │
├─────────────────────────────────────────────────────────────┤
│  Role: clo835-role                                         │
│  • Permissions: get, list namespaces                       │
│  • Principle of least privilege                            │
├─────────────────────────────────────────────────────────────┤
│  RoleBinding: clo835-rolebinding                           │
│  • Links clo835-sa to clo835-role                         │
│  • Namespace-scoped permissions                            │
└─────────────────────────────────────────────────────────────┘
```

### Security Controls

1. **Network Security**:
   - Private subnets for worker nodes
   - Security groups with minimal required ports
   - No direct SSH access to worker nodes

2. **Container Security**:
   - Non-root user in containers
   - Read-only root filesystem where possible
   - Resource limits and requests

3. **Data Security**:
   - Secrets stored in Kubernetes secrets
   - S3 bucket with private access only
   - EBS encryption at rest

4. **Access Control**:
   - IAM roles for AWS services
   - RBAC for Kubernetes resources
   - Service accounts with limited permissions

## Data Flow

### Application Request Flow

```
1. User Request → Internet Gateway
2. Internet Gateway → Application Load Balancer
3. ALB → Target Group → Worker Node
4. Worker Node → webapp-service (ClusterIP)
5. webapp-service → webapp Pod
6. webapp Pod → mysql-service (ClusterIP)
7. mysql-service → MySQL Pod
8. MySQL Pod → EBS Volume (data persistence)
```

### Background Image Flow

```
1. Application Startup → ConfigMap (S3 URL)
2. webapp Pod → AWS S3 API (using IAM role)
3. S3 Bucket → Image Download → Pod local storage
4. User Request → Flask serves local image file
```

### CI/CD Data Flow

```
1. Code Push → GitHub Repository
2. GitHub Actions → Build Docker Image
3. GitHub Actions → Push to ECR
4. Deployment → ECR Pull → Worker Nodes
5. Kubernetes → Pod Creation → Image Run
```

## Infrastructure Components

### Terraform-Managed Resources

```yaml
Core Infrastructure:
  - VPC with public/private subnets
  - Internet Gateway and NAT Gateways
  - Security Groups and NACLs
  - EKS Cluster and Node Groups
  - ECR Repository
  - IAM Roles and Policies

Computed Resources:
  - EBS Volumes (dynamic provisioning)
  - Load Balancers (via Kubernetes services)
  - DNS records (automatic ALB integration)
```

### Kubernetes-Managed Resources

```yaml
Workloads:
  - Deployments: webapp-deployment, mysql-deployment
  - ReplicaSets: (managed by deployments)
  - Pods: (managed by replicasets)

Services:
  - webapp-service (LoadBalancer)
  - mysql-service (ClusterIP)

Configuration:
  - ConfigMaps: webapp-config
  - Secrets: mysql-secret, aws-secret, ecr-secret

Storage:
  - PersistentVolumes: (dynamic provisioning)
  - PersistentVolumeClaims: mysql-pvc

Security:
  - ServiceAccounts: clo835-sa
  - Roles: clo835-role
  - RoleBindings: clo835-rolebinding
```

## Deployment Architecture

### Multi-Environment Support

```
┌─────────────────────────────────────────────────────────────┐
│                    Environment Strategy                     │
├─────────────────────────────────────────────────────────────┤
│  Development:                                               │
│  • Local Docker Compose                                    │
│  • Minikube or kind cluster                                │
│  • Local ECR or Docker Hub                                 │
├─────────────────────────────────────────────────────────────┤
│  Staging/Testing:                                           │
│  • Dedicated EKS cluster                                   │
│  • Shared ECR repository                                   │
│  • Automated testing pipeline                              │
├─────────────────────────────────────────────────────────────┤
│  Production:                                                │
│  • Production EKS cluster                                  │
│  • Multi-AZ deployment                                     │
│  • Production-grade monitoring                             │
└─────────────────────────────────────────────────────────────┘
```

### Scaling Architecture

```
Horizontal Scaling:
  - Webapp Pods: 1-10 replicas (HPA)
  - MySQL: Single instance (StatefulSet recommended for HA)
  - Worker Nodes: 2-5 nodes (Cluster Autoscaler)

Vertical Scaling:
  - Pod resource requests/limits
  - EBS volume expansion
  - Instance type upgrades
```

## Monitoring and Observability

### Logging Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Logging Stack                          │
├─────────────────────────────────────────────────────────────┤
│  Application Logs:                                          │
│  • Flask application logs                                  │
│  • MySQL error and slow query logs                         │
│  • Custom business logic logs                              │
├─────────────────────────────────────────────────────────────┤
│  System Logs:                                              │
│  • Kubernetes events                                       │
│  • Node system logs                                        │
│  • Container runtime logs                                  │
├─────────────────────────────────────────────────────────────┤
│  Infrastructure Logs:                                       │
│  • EKS control plane logs                                  │
│  • VPC Flow Logs                                           │
│  • Load Balancer access logs                               │
└─────────────────────────────────────────────────────────────┘
```

### Metrics and Monitoring

```
Performance Metrics:
  - CPU and memory utilization
  - Network I/O and latency
  - Disk I/O and storage usage
  - Database connection pools

Business Metrics:
  - Request count and response times
  - Error rates and success rates
  - User sessions and transactions
  - Feature usage analytics

Infrastructure Metrics:
  - Cluster resource utilization
  - Pod restart counts
  - Storage usage trends
  - Cost optimization metrics
```

### Health Checks and Probes

```yaml
Kubernetes Probes:
  Liveness Probe:
    - Ensures container is running
    - Restarts failed containers
    
  Readiness Probe:
    - Ensures container ready for traffic
    - Removes from service endpoints
    
  Startup Probe:
    - Handles slow-starting containers
    - Prevents premature liveness failures

Load Balancer Health Checks:
  - Target group health checks
  - Custom health endpoints
  - Automatic failover
```

## Best Practices Implementation

### Security Best Practices

1. **Principle of Least Privilege**: Minimal IAM and RBAC permissions
2. **Defense in Depth**: Multiple security layers
3. **Secrets Management**: No hardcoded credentials
4. **Network Segmentation**: Private subnets and security groups
5. **Encryption**: Data at rest and in transit

### Operational Best Practices

1. **Infrastructure as Code**: All infrastructure version-controlled
2. **Automated Testing**: CI/CD pipeline with tests
3. **Monitoring and Alerting**: Comprehensive observability
4. **Backup and Recovery**: Data persistence and backup strategies
5. **Cost Optimization**: Resource limits and cleanup procedures

### Development Best Practices

1. **Container Optimization**: Multi-stage builds and minimal images
2. **Configuration Management**: Environment-specific configurations
3. **Logging Standards**: Structured logging with correlation IDs
4. **Error Handling**: Graceful degradation and retry logic
5. **Documentation**: Comprehensive technical documentation

---

This architecture provides a robust, scalable, and secure foundation for the CLO835 Final Project, demonstrating modern cloud-native application development and deployment practices.