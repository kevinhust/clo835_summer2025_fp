# CLO835 Final Project - Cost Analysis and Optimization

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [Cost Breakdown by Service](#cost-breakdown-by-service)
3. [Monthly Cost Projection](#monthly-cost-projection)
4. [Cost Optimization Strategies](#cost-optimization-strategies)
5. [Resource Usage Analysis](#resource-usage-analysis)
6. [Cleanup Procedures](#cleanup-procedures)
7. [Cost Monitoring and Alerts](#cost-monitoring-and-alerts)
8. [Alternative Architectures](#alternative-architectures)

## Executive Summary

This cost analysis provides a comprehensive breakdown of AWS resource costs for the CLO835 Final Project implementation. The analysis includes actual resource usage, projected monthly costs, optimization recommendations, and cleanup procedures to manage expenses effectively.

### Key Cost Highlights

- **Estimated Monthly Cost**: $120-180 USD (varies by usage)
- **Primary Cost Drivers**: EKS cluster ($72/month) and EC2 instances ($69/month per node)
- **Cost Optimization Potential**: 40-60% savings through right-sizing and scheduling
- **Cleanup Savings**: 100% cost elimination when resources are properly cleaned up

### Cost Management Recommendations

1. **Immediate Actions**: Implement automated cleanup scripts
2. **Short-term**: Right-size instances and implement scheduling
3. **Long-term**: Consider Spot instances and reserved capacity

## Cost Breakdown by Service

### Amazon EKS (Elastic Kubernetes Service)

**Control Plane Costs**:
```
Service: Amazon EKS
Cost: $0.10 per hour per cluster
Monthly Cost: $72.00 (24/7 operation)
Annual Cost: $864.00

Components:
- Kubernetes control plane management
- etcd storage and management
- API server operations
- Scheduler and controller manager
```

**Cost Optimization Options**:
- ✅ **Shared Cluster**: Use one cluster for multiple environments
- ✅ **Development Scheduling**: Stop cluster during off-hours (save 60-70%)
- ❌ **Free Tier**: Not available for EKS control plane

### Amazon EC2 (Worker Nodes)

**Instance Costs**:
```
Instance Type: t3.medium
vCPUs: 2
Memory: 4 GiB
Cost per hour: $0.0416 (us-east-1)
Cost per instance per month: $30.24 (24/7)

Node Group Configuration:
- Desired capacity: 2 nodes
- Minimum capacity: 1 node  
- Maximum capacity: 4 nodes

Monthly Cost Calculation:
Base (2 nodes): $60.48
Auto-scaling additional nodes: $30.24 per node
Total Range: $60.48 - $121.92
```

**Alternative Instance Types**:
| Instance Type | vCPU | Memory | Cost/Hour | Monthly Cost | Use Case |
|---------------|------|---------|-----------|--------------|----------|
| t3.micro | 2 | 1 GiB | $0.0104 | $7.56 | Development only |
| t3.small | 2 | 2 GiB | $0.0208 | $15.12 | Light workloads |
| t3.medium | 2 | 4 GiB | $0.0416 | $30.24 | **Current choice** |
| t3.large | 2 | 8 GiB | $0.0832 | $60.48 | Heavy workloads |

### Amazon EBS (Elastic Block Store)

**Storage Costs**:
```
MySQL Persistent Volume:
- Volume Type: gp2 (General Purpose SSD)
- Size: 3 GiB
- Cost: $0.10 per GiB per month
- Monthly Cost: $0.30

Root Volumes (per worker node):
- Volume Type: gp2
- Size: 20 GiB (default)
- Cost per node: $2.00/month
- Total for 2 nodes: $4.00/month

Total EBS Monthly Cost: $4.30
```

**Cost Optimization**:
- ✅ **Right-sizing**: Use minimum required storage
- ✅ **gp3 Migration**: 20% cost savings vs gp2
- ✅ **Lifecycle Policies**: Delete unused snapshots

### Application Load Balancer (ALB)

**Load Balancer Costs**:
```
ALB Fixed Cost: $0.0225 per hour
Monthly Fixed Cost: $16.43

Load Balancer Capacity Units (LCU):
- New connections: 25 per second
- Active connections: 3,000 per minute
- Bandwidth: 2.22 Mbps
- Rule evaluations: 1,000 per second

Estimated LCU Usage: 1-2 LCUs
LCU Cost: $0.008 per hour per LCU
Monthly LCU Cost: $5.76 - $11.52

Total ALB Monthly Cost: $22.19 - $27.95
```

### Amazon ECR (Elastic Container Registry)

**Registry Costs**:
```
Storage Cost: $0.10 per GiB per month
Data Transfer: $0.09 per GiB (outbound)

Estimated Usage:
- Image size: ~500 MiB per image
- Number of images: 5-10 (with versioning)
- Total storage: 2.5-5 GiB
- Monthly storage cost: $0.25 - $0.50

Data Transfer:
- Image pulls: 50-100 per month
- Transfer cost: $2.25 - $4.50

Total ECR Monthly Cost: $2.50 - $5.00
```

### Amazon S3 (Simple Storage Service)

**Storage Costs**:
```
S3 Standard Storage: $0.023 per GiB per month
Background Images: ~10 MiB total
Monthly Storage Cost: ~$0.01

S3 Requests:
- GET requests: $0.0004 per 1,000 requests
- PUT requests: $0.005 per 1,000 requests
- Estimated requests: 1,000-5,000/month
- Monthly Request Cost: $0.002 - $0.025

Total S3 Monthly Cost: $0.01 - $0.04
```

### Data Transfer Costs

**Network Transfer Pricing**:
```
Internet Gateway:
- Inbound: Free
- Outbound: $0.09 per GiB (first 1 GiB free)

NAT Gateway:
- Per hour: $0.045
- Data processing: $0.045 per GiB
- Monthly cost (2 AZs): $65.70 + data charges

Estimated monthly data transfer: 10-50 GiB
Data transfer cost: $4.50 - $22.50

Total Data Transfer Cost: $70.20 - $88.20
```

## Monthly Cost Projection

### Base Configuration Cost Breakdown

```
Service                     Monthly Cost (USD)
----------------------------------------
Amazon EKS Control Plane    $72.00
EC2 Instances (2x t3.medium) $60.48
Application Load Balancer   $22.19 - $27.95
NAT Gateway (2 AZs)        $65.70
EBS Storage                $4.30
ECR Registry               $2.50 - $5.00
S3 Storage                 $0.01 - $0.04
Data Transfer              $4.50 - $22.50
----------------------------------------
TOTAL                      $231.68 - $257.97

Actual Usage Estimate      $180.00 - $220.00
(with typical dev usage patterns)
```

### Cost by Usage Pattern

**Development Usage (8 hours/day, 5 days/week)**:
```
EKS Control Plane: $72.00 (always on)
EC2 Instances: $14.52 (scheduled)
Load Balancer: $5.48 (scheduled)
Other Services: $10.00
Total: ~$102.00/month (55% savings)
```

**Testing Usage (12 hours/day, 7 days/week)**:
```
EKS Control Plane: $72.00
EC2 Instances: $30.24
Load Balancer: $11.00
Other Services: $15.00
Total: ~$128.24/month (35% savings)
```

**Production Usage (24/7 with high availability)**:
```
EKS Control Plane: $72.00
EC2 Instances: $90.72 (3 nodes)
Load Balancer: $30.00
NAT Gateway: $65.70
Other Services: $20.00
Total: ~$278.42/month
```

## Cost Optimization Strategies

### Immediate Cost Reduction (0-1 week)

**1. Automated Resource Cleanup**:
```bash
# Implement cleanup scripts
./scripts/cleanup-all.sh

# Schedule cleanup jobs
crontab -e
# Add: 0 18 * * 5 /path/to/cleanup-all.sh --k8s-only
```
**Potential Savings**: 100% when not in use

**2. Right-size Worker Nodes**:
```yaml
# Terraform configuration update
instance_types = ["t3.small", "t3.medium"]
desired_capacity = 1
min_size = 1
max_size = 2
```
**Potential Savings**: 50% on EC2 costs

**3. EBS Volume Optimization**:
```yaml
# Reduce MySQL PVC size
storage: 1Gi  # Instead of 3Gi
storageClassName: gp3  # Instead of gp2
```
**Potential Savings**: 67% on EBS costs + 20% gp3 discount

### Short-term Optimization (1-4 weeks)

**1. Implement Cluster Autoscaler**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cluster-autoscaler
  namespace: kube-system
spec:
  template:
    spec:
      containers:
      - image: k8s.gcr.io/autoscaling/cluster-autoscaler:v1.21.0
        name: cluster-autoscaler
        command:
        - ./cluster-autoscaler
        - --v=4
        - --stderrthreshold=info
        - --cloud-provider=aws
        - --skip-nodes-with-local-storage=false
        - --expander=least-waste
        - --node-group-auto-discovery=asg:tag=k8s.io/cluster-autoscaler/enabled,k8s.io/cluster-autoscaler/clo835-cluster
        - --balance-similar-node-groups
        - --skip-nodes-with-system-pods=false
        - --scale-down-delay-after-add=10m
        - --scale-down-unneeded-time=10m
```
**Potential Savings**: 30-40% on EC2 costs

**2. Horizontal Pod Autoscaler**:
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: webapp-hpa
  namespace: clo835
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: webapp-deployment
  minReplicas: 1
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```
**Potential Savings**: 20-30% by optimizing pod count

**3. Scheduled Scaling**:
```bash
# Create scheduled scaling scripts
#!/bin/bash
# scale-down.sh
kubectl scale deployment webapp-deployment --replicas=0 -n clo835
kubectl scale deployment mysql-deployment --replicas=0 -n clo835

# scale-up.sh  
kubectl scale deployment mysql-deployment --replicas=1 -n clo835
kubectl scale deployment webapp-deployment --replicas=1 -n clo835

# Schedule with cron
# Scale down at 6 PM: 0 18 * * 1-5 /path/to/scale-down.sh
# Scale up at 8 AM: 0 8 * * 1-5 /path/to/scale-up.sh
```
**Potential Savings**: 60-70% for development usage

### Long-term Optimization (1-3 months)

**1. Spot Instance Integration**:
```yaml
# Terraform mixed instance policy
mixed_instances_policy {
  instances_distribution {
    on_demand_base_capacity = 1
    on_demand_percentage_above_base_capacity = 0
    spot_allocation_strategy = "diversified"
  }
  
  launch_template {
    launch_template_specification {
      launch_template_id = aws_launch_template.worker.id
      version = "$Latest"
    }
    
    override {
      instance_type = "t3.medium"
      spot_price = "0.025"  # 40% of on-demand price
    }
    
    override {
      instance_type = "t3.small"
      spot_price = "0.013"  # 40% of on-demand price
    }
  }
}
```
**Potential Savings**: 60-70% on EC2 costs

**2. Reserved Instance Strategy**:
```
1-Year Term, No Upfront:
- t3.medium: $0.0291/hour (30% savings)
- Annual savings: ~$318

3-Year Term, All Upfront:
- t3.medium: $0.0246/hour (41% savings)  
- Total 3-year savings: ~$1,277
```
**Potential Savings**: 30-41% on EC2 costs

**3. Alternative Architecture**:
```yaml
# Serverless option with Fargate
apiVersion: v1
kind: Namespace
metadata:
  name: clo835
  labels:
    fargate: enabled

# Fargate pricing: $0.04048 per vCPU per hour + $0.004445 per GiB per hour
# Typical webapp: 0.25 vCPU, 0.5 GiB = $0.01234/hour = $8.99/month
```
**Potential Savings**: 70-80% for light workloads

## Resource Usage Analysis

### CPU and Memory Utilization

**Current Resource Allocation**:
```yaml
webapp-deployment:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"

mysql-deployment:
  requests:
    memory: "512Mi"
    cpu: "500m"
  limits:
    memory: "1Gi"
    cpu: "1000m"
```

**Actual Usage Monitoring**:
```bash
# Monitor resource usage
kubectl top pods -n clo835

# Typical usage observed:
# webapp: 50-100m CPU, 128-200Mi memory
# mysql: 100-200m CPU, 256-400Mi memory
```

**Right-sizing Recommendations**:
```yaml
webapp-deployment:
  requests:
    memory: "128Mi"  # Reduced from 256Mi
    cpu: "100m"      # Reduced from 250m
  limits:
    memory: "256Mi"  # Reduced from 512Mi
    cpu: "300m"      # Reduced from 500m

mysql-deployment:
  requests:
    memory: "256Mi"  # Reduced from 512Mi
    cpu: "200m"      # Reduced from 500m
  limits:
    memory: "512Mi"  # Reduced from 1Gi
    cpu: "500m"      # Reduced from 1000m
```

### Storage Usage Analysis

**EBS Volume Utilization**:
```bash
# Check storage usage in MySQL pod
kubectl exec -it mysql-pod -n clo835 -- df -h /var/lib/mysql

# Typical usage:
# Total: 3Gi
# Used: 200-500Mi (database + logs)
# Available: 2.5-2.8Gi
```

**Storage Optimization**:
```yaml
# Optimized PVC configuration
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pvc
  namespace: clo835
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gp3  # Changed from gp2
  resources:
    requests:
      storage: 1Gi      # Reduced from 3Gi
```

### Network Usage Analysis

**Data Transfer Patterns**:
```
Inbound Traffic:
- User web requests: 1-10 GB/month
- S3 image downloads: 0.1-0.5 GB/month
- ECR image pulls: 2-5 GB/month

Outbound Traffic:
- Web responses: 1-10 GB/month
- Health checks: 0.5 GB/month
- Logs and monitoring: 1-2 GB/month

Total Monthly Transfer: 5-30 GB
Cost Impact: $0.45 - $2.70/month
```

## Cleanup Procedures

### Immediate Cleanup (Zero Cost)

**1. Automated Cleanup Script**:
```bash
# Use comprehensive cleanup script
./scripts/cleanup-all.sh

# This removes:
# - Kubernetes namespace and all resources
# - Terraform infrastructure
# - ECR images
# - Orphaned EBS volumes
```

**2. Manual Verification**:
```bash
# Verify EKS cluster deletion
aws eks list-clusters --region us-east-1

# Verify ECR repositories
aws ecr describe-repositories --region us-east-1

# Verify EBS volumes
aws ec2 describe-volumes --region us-east-1 \
  --filters "Name=tag:kubernetes.io/cluster/clo835-cluster,Values=owned"

# Verify Load Balancers
aws elbv2 describe-load-balancers --region us-east-1
```

### Partial Cleanup (Development Mode)

**1. Scale Down During Off-Hours**:
```bash
# Scale applications to zero
kubectl scale deployment webapp-deployment --replicas=0 -n clo835
kubectl scale deployment mysql-deployment --replicas=0 -n clo835

# This maintains cluster but eliminates pod resource usage
# Savings: ~20-30% of total cost
```

**2. Cluster Stop/Start**:
```bash
# Note: EKS clusters cannot be stopped, only deleted
# Alternative: Use Fargate with scheduled scaling

# Scale node group to zero
aws eks update-nodegroup-config \
  --cluster-name clo835-cluster \
  --nodegroup-name clo835-workers \
  --scaling-config minSize=0,maxSize=0,desiredSize=0
```

### Emergency Cleanup (Cost Control)

**1. Force Deletion Commands**:
```bash
# Force delete namespace
kubectl delete namespace clo835 --force --grace-period=0

# Force destroy Terraform (be careful!)
cd terraform
terraform destroy -auto-approve

# Delete all ECR images
aws ecr list-images --repository-name clo835-webapp \
  --query 'imageIds[*]' --output json | \
  aws ecr batch-delete-image --repository-name clo835-webapp \
  --image-ids file:///dev/stdin
```

**2. Cost-Based Deletion Priority**:
```
Priority 1 (Highest Cost): NAT Gateway, Load Balancer
Priority 2 (Medium Cost): EC2 Instances, EKS Control Plane  
Priority 3 (Low Cost): EBS Volumes, ECR Storage, S3
```

## Cost Monitoring and Alerts

### AWS Billing Alerts Setup

**1. CloudWatch Billing Alarm**:
```bash
# Create billing alarm for $50 threshold
aws cloudwatch put-metric-alarm \
  --alarm-name "CLO835-Project-Cost-Alert" \
  --alarm-description "Alert when CLO835 costs exceed $50" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 86400 \
  --threshold 50 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=Currency,Value=USD \
  --evaluation-periods 1 \
  --alarm-actions "arn:aws:sns:us-east-1:ACCOUNT:billing-alerts"
```

**2. Cost Budget Creation**:
```json
{
  "Budget": {
    "BudgetName": "CLO835-Monthly-Budget",
    "TimeUnit": "MONTHLY",
    "BudgetType": "COST",
    "BudgetLimit": {
      "Amount": "100",
      "Unit": "USD"
    },
    "CostFilters": {
      "TagKey": ["Project"],
      "TagValue": ["CLO835"]
    }
  },
  "NotificationsWithSubscribers": [
    {
      "Notification": {
        "NotificationType": "ACTUAL",
        "ComparisonOperator": "GREATER_THAN",
        "Threshold": 80
      },
      "Subscribers": [
        {
          "SubscriptionType": "EMAIL",
          "Address": "your-email@example.com"
        }
      ]
    }
  ]
}
```

### Cost Tracking Scripts

**1. Daily Cost Check**:
```bash
#!/bin/bash
# daily-cost-check.sh

# Get current month costs
COST=$(aws ce get-cost-and-usage \
  --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --query 'ResultsByTime[0].Total.BlendedCost.Amount' \
  --output text)

echo "Current month CLO835 costs: \$${COST}"

# Alert if over threshold
if (( $(echo "$COST > 75" | bc -l) )); then
  echo "WARNING: Costs exceed $75 threshold!"
  # Send notification or trigger cleanup
fi
```

**2. Resource Inventory Script**:
```bash
#!/bin/bash
# resource-inventory.sh

echo "=== CLO835 Resource Inventory ==="
echo "EKS Clusters:"
aws eks list-clusters --query 'clusters' --output table

echo "EC2 Instances:"
aws ec2 describe-instances \
  --filters "Name=tag:Project,Values=CLO835" \
  --query 'Reservations[].Instances[].{ID:InstanceId,Type:InstanceType,State:State.Name}' \
  --output table

echo "Load Balancers:"
aws elbv2 describe-load-balancers \
  --query 'LoadBalancers[?contains(LoadBalancerName, `k8s`)].{Name:LoadBalancerName,State:State.Code}' \
  --output table

echo "EBS Volumes:"
aws ec2 describe-volumes \
  --filters "Name=tag:kubernetes.io/cluster/clo835-cluster,Values=owned" \
  --query 'Volumes[].{ID:VolumeId,Size:Size,State:State}' \
  --output table
```

## Alternative Architectures

### Cost-Optimized Development Architecture

**Serverless Alternative**:
```yaml
# AWS Fargate + RDS Serverless
Components:
- EKS Fargate for application pods
- RDS Aurora Serverless for database
- S3 for static content with CloudFront
- API Gateway for external access

Estimated Monthly Cost:
- Fargate: $15-30 (0.25 vCPU, 0.5GB)
- Aurora Serverless: $25-50 (minimal usage)
- CloudFront: $1-5
- S3: <$1
Total: $41-86/month (60% savings)
```

**Minimal Development Setup**:
```yaml
# Single-node cluster with local storage
Components:
- 1x t3.small instance ($15.12/month)
- Local storage (no EBS)
- NodePort service (no LoadBalancer)
- Kind cluster alternative for local dev

Estimated Monthly Cost:
- EC2: $15.12
- EKS: $72 (unavoidable)
- Minimal networking: $5
Total: $92.12/month (50% savings)
```

### Production-Ready Cost-Effective Architecture

**Multi-AZ with Cost Controls**:
```yaml
# Production architecture with cost optimization
Components:
- 3x t3.medium instances (multi-AZ)
- 1x On-demand + 2x Spot instances
- RDS MySQL (db.t3.micro)
- Application Load Balancer
- CloudWatch monitoring

Estimated Monthly Cost:
- EKS: $72
- EC2 On-demand: $30.24
- EC2 Spot (2x): $24.19 (60% savings)
- RDS: $16.79
- ALB: $25
- Monitoring: $10
Total: $178.22/month
```

## Recommendations Summary

### Immediate Actions (Week 1)
1. ✅ Implement automated cleanup scripts
2. ✅ Set up billing alerts and budgets
3. ✅ Right-size EC2 instances to t3.small
4. ✅ Reduce EBS storage to 1Gi with gp3

**Expected Savings**: 40-50%

### Short-term Actions (Month 1)
1. ✅ Implement cluster autoscaler
2. ✅ Add horizontal pod autoscaler
3. ✅ Schedule scaling for development hours
4. ✅ Migrate to Spot instances for non-production

**Expected Savings**: 60-70%

### Long-term Considerations (Month 2-3)
1. ✅ Evaluate Fargate for variable workloads
2. ✅ Consider RDS Aurora Serverless for database
3. ✅ Implement reserved instances for stable workloads
4. ✅ Add CloudFront CDN for static content

**Expected Savings**: 70-80%

### Cost Management Best Practices
1. **Daily Monitoring**: Check costs and resource usage daily
2. **Weekly Review**: Analyze cost trends and optimize resources
3. **Monthly Cleanup**: Remove unused resources and images
4. **Quarterly Planning**: Review architecture for cost optimization

---

**Important Note**: Always prioritize learning objectives over cost optimization in educational environments. The goal is to understand enterprise-grade architectures while maintaining cost awareness for practical application.