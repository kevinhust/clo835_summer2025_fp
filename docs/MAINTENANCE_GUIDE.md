# CLO835 Final Project - Maintenance and Operations Guide

## Table of Contents
1. [Overview](#overview)
2. [Monitoring and Alerting](#monitoring-and-alerting)
3. [Backup and Recovery](#backup-and-recovery)
4. [Scaling and Performance](#scaling-and-performance)
5. [Security Maintenance](#security-maintenance)
6. [Cost Management](#cost-management)
7. [Troubleshooting](#troubleshooting)
8. [Regular Maintenance Tasks](#regular-maintenance-tasks)

## Overview

This maintenance guide provides comprehensive procedures for operating, monitoring, and maintaining the CLO835 Final Project infrastructure in a production-like environment. It covers daily operations, preventive maintenance, incident response, and optimization strategies.

### Maintenance Philosophy

1. **Proactive Monitoring**: Identify issues before they impact users
2. **Automated Operations**: Reduce manual intervention and human error
3. **Security First**: Maintain security posture through regular updates
4. **Cost Optimization**: Continuously optimize resource usage and costs
5. **Documentation**: Keep operational procedures current and accessible

### Responsibility Matrix

| Area | Primary | Secondary | Escalation |
|------|---------|-----------|------------|
| Application Performance | DevOps Engineer | Developer | Team Lead |
| Infrastructure Health | Cloud Engineer | DevOps Engineer | Architecture Team |
| Security Incidents | Security Engineer | DevOps Engineer | CISO |
| Cost Management | FinOps Engineer | Cloud Engineer | Finance Team |
| Database Operations | Database Admin | DevOps Engineer | Senior DBA |

## Monitoring and Alerting

### CloudWatch Integration

**1. Essential Metrics to Monitor**:
```yaml
EKS Cluster Metrics:
  - cluster_failed_request_count
  - cluster_request_total
  - cluster_autoscaler_nodes_count
  - cluster_autoscaler_unschedulable_pods_count

Node Metrics:
  - node_cpu_utilization
  - node_memory_utilization
  - node_disk_utilization
  - node_network_utilization

Application Metrics:
  - pod_cpu_utilization
  - pod_memory_utilization
  - pod_restart_count
  - container_last_seen

Database Metrics:
  - mysql_connections_current
  - mysql_queries_per_second
  - mysql_slow_queries
  - mysql_innodb_buffer_pool_utilization
```

**2. CloudWatch Dashboards Setup**:
```json
{
  "widgets": [
    {
      "type": "metric",
      "properties": {
        "metrics": [
          ["AWS/EKS", "cluster_failed_request_count", "ClusterName", "clo835-cluster"],
          ["ContainerInsights", "pod_cpu_utilization", "Namespace", "clo835"],
          ["ContainerInsights", "pod_memory_utilization", "Namespace", "clo835"]
        ],
        "period": 300,
        "stat": "Average",
        "region": "us-east-1",
        "title": "EKS Cluster Health"
      }
    }
  ]
}
```

**3. Alert Configuration**:
```bash
# High CPU utilization alert
aws cloudwatch put-metric-alarm \
  --alarm-name "CLO835-High-CPU" \
  --alarm-description "High CPU utilization in clo835 namespace" \
  --metric-name pod_cpu_utilization \
  --namespace ContainerInsights \
  --statistic Average \
  --period 300 \
  --threshold 80 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=Namespace,Value=clo835 \
  --evaluation-periods 2 \
  --alarm-actions "arn:aws:sns:us-east-1:ACCOUNT:clo835-alerts"

# Pod restart alert
aws cloudwatch put-metric-alarm \
  --alarm-name "CLO835-Pod-Restarts" \
  --alarm-description "Frequent pod restarts detected" \
  --metric-name pod_restart_count \
  --namespace ContainerInsights \
  --statistic Sum \
  --period 900 \
  --threshold 5 \
  --comparison-operator GreaterThanThreshold \
  --dimensions Name=Namespace,Value=clo835 \
  --evaluation-periods 1 \
  --alarm-actions "arn:aws:sns:us-east-1:ACCOUNT:clo835-alerts"
```

### Application Health Checks

**1. Kubernetes Health Probes**:
```yaml
# Enhanced webapp deployment with health checks
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-deployment
  namespace: clo835
spec:
  template:
    spec:
      containers:
      - name: webapp
        image: ECR_REPOSITORY:latest
        ports:
        - containerPort: 81
        livenessProbe:
          httpGet:
            path: /health
            port: 81
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /ready
            port: 81
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        startupProbe:
          httpGet:
            path: /health
            port: 81
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 30
```

**2. Health Check Endpoints**:
```python
# Add to Flask application (app.py)
@app.route('/health')
def health_check():
    """Health check endpoint for liveness probe"""
    try:
        # Test database connection
        cursor = db_conn.cursor()
        cursor.execute("SELECT 1")
        cursor.close()
        
        # Test S3 connectivity (optional)
        if s3_client:
            s3_client.list_objects_v2(Bucket='your-bucket-name', MaxKeys=1)
        
        return {'status': 'healthy', 'timestamp': datetime.utcnow().isoformat()}, 200
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return {'status': 'unhealthy', 'error': str(e)}, 500

@app.route('/ready')
def readiness_check():
    """Readiness check endpoint for readiness probe"""
    try:
        # Quick check - just verify app is responsive
        return {'status': 'ready', 'timestamp': datetime.utcnow().isoformat()}, 200
    except Exception as e:
        logger.error(f"Readiness check failed: {e}")
        return {'status': 'not ready', 'error': str(e)}, 500
```

### Log Management

**1. Centralized Logging Setup**:
```yaml
# Fluent Bit DaemonSet for log collection
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluent-bit
  namespace: kube-system
spec:
  selector:
    matchLabels:
      name: fluent-bit
  template:
    metadata:
      labels:
        name: fluent-bit
    spec:
      containers:
      - name: fluent-bit
        image: amazon/aws-for-fluent-bit:2.25.0
        env:
        - name: AWS_REGION
          value: "us-east-1"
        - name: CLUSTER_NAME
          value: "clo835-cluster"
        - name: HTTP_SERVER
          value: "On"
        - name: HTTP_PORT
          value: "2020"
        - name: READ_FROM_HEAD
          value: "Off"
        - name: READ_FROM_TAIL
          value: "On"
        - name: HOST_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        - name: CI_VERSION
          value: "k8s/1.3.9"
        resources:
          limits:
            memory: 200Mi
          requests:
            cpu: 500m
            memory: 100Mi
        volumeMounts:
        - name: varlog
          mountPath: /var/log
          readOnly: true
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
        - name: fluent-bit-config
          mountPath: /fluent-bit/etc/
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
      - name: fluent-bit-config
        configMap:
          name: fluent-bit-config
```

**2. Log Analysis Queries**:
```bash
# CloudWatch Insights queries for troubleshooting

# Application errors
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp desc
| limit 100

# Database connection issues
fields @timestamp, @message
| filter @message like /database/ or @message like /mysql/
| filter @message like /error/ or @message like /fail/
| sort @timestamp desc

# High response times
fields @timestamp, @message
| filter @message like /response_time/
| stats avg(response_time) by bin(5m)
```

## Backup and Recovery

### Database Backup Strategy

**1. Automated EBS Snapshots**:
```bash
#!/bin/bash
# backup-mysql.sh

# Get MySQL PV volume ID
VOLUME_ID=$(kubectl get pv $(kubectl get pvc mysql-pvc -n clo835 -o jsonpath='{.spec.volumeName}') -o jsonpath='{.spec.awsElasticBlockStore.volumeID}' | cut -d'/' -f4)

# Create snapshot with retention tags
aws ec2 create-snapshot \
  --volume-id $VOLUME_ID \
  --description "CLO835 MySQL backup $(date +%Y-%m-%d_%H-%M)" \
  --tag-specifications "ResourceType=snapshot,Tags=[{Key=Project,Value=CLO835},{Key=RetentionDays,Value=7},{Key=AutoDelete,Value=true}]"

echo "Backup snapshot created for volume $VOLUME_ID"
```

**2. Automated Backup Schedule**:
```yaml
# Kubernetes CronJob for automated backups
apiVersion: batch/v1
kind: CronJob
metadata:
  name: mysql-backup
  namespace: clo835
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: mysql-backup
            image: amazon/aws-cli:latest
            command:
            - /bin/bash
            - -c
            - |
              # Get volume ID and create snapshot
              apt-get update && apt-get install -y jq
              VOLUME_ID=$(kubectl get pv $(kubectl get pvc mysql-pvc -n clo835 -o jsonpath='{.spec.volumeName}') -o jsonpath='{.spec.awsElasticBlockStore.volumeID}' | cut -d'/' -f4)
              aws ec2 create-snapshot --volume-id $VOLUME_ID --description "Auto backup $(date)"
            env:
            - name: AWS_DEFAULT_REGION
              value: "us-east-1"
          restartPolicy: OnFailure
          serviceAccountName: backup-service-account
```

**3. Database Logical Backup**:
```bash
#!/bin/bash
# mysql-logical-backup.sh

# Create MySQL dump
kubectl exec -n clo835 deployment/mysql-deployment -- \
  mysqldump -u root -p$MYSQL_ROOT_PASSWORD --all-databases > mysql-backup-$(date +%Y%m%d).sql

# Upload to S3 for long-term storage
aws s3 cp mysql-backup-$(date +%Y%m%d).sql s3://clo835-backups/mysql/

# Cleanup old local backups
find . -name "mysql-backup-*.sql" -mtime +7 -delete
```

### Application Backup

**1. ConfigMap and Secrets Backup**:
```bash
#!/bin/bash
# backup-configs.sh

# Backup all ConfigMaps and Secrets
kubectl get configmaps -n clo835 -o yaml > configmaps-backup-$(date +%Y%m%d).yaml
kubectl get secrets -n clo835 -o yaml > secrets-backup-$(date +%Y%m%d).yaml

# Backup all manifests
kubectl get all -n clo835 -o yaml > all-resources-backup-$(date +%Y%m%d).yaml

# Store in S3
aws s3 sync . s3://clo835-backups/configs/ --exclude "*" --include "*backup*.yaml"
```

**2. ECR Image Backup**:
```bash
#!/bin/bash
# backup-images.sh

# List all images in ECR
aws ecr list-images --repository-name clo835-webapp --query 'imageIds[*].imageTag' --output text > image-tags.txt

# Create backup repository
aws ecr create-repository --repository-name clo835-webapp-backup || true

# Copy latest production images to backup repository
for tag in $(head -5 image-tags.txt); do
  docker pull $ECR_REGISTRY/clo835-webapp:$tag
  docker tag $ECR_REGISTRY/clo835-webapp:$tag $ECR_REGISTRY/clo835-webapp-backup:$tag
  docker push $ECR_REGISTRY/clo835-webapp-backup:$tag
done
```

### Disaster Recovery Procedures

**1. Complete Infrastructure Recovery**:
```bash
#!/bin/bash
# disaster-recovery.sh

echo "Starting CLO835 disaster recovery..."

# Step 1: Restore infrastructure with Terraform
cd terraform
terraform init
terraform apply -auto-approve

# Step 2: Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name clo835-cluster

# Step 3: Restore from backup snapshots
LATEST_SNAPSHOT=$(aws ec2 describe-snapshots \
  --owner-ids self \
  --filters "Name=tag:Project,Values=CLO835" \
  --query 'Snapshots | sort_by(@, &StartTime) | [-1].SnapshotId' \
  --output text)

# Step 4: Create volume from snapshot
aws ec2 create-volume \
  --snapshot-id $LATEST_SNAPSHOT \
  --availability-zone us-east-1a \
  --tag-specifications "ResourceType=volume,Tags=[{Key=Project,Value=CLO835}]"

# Step 5: Deploy Kubernetes resources
kubectl apply -f k8s-manifests/

echo "Disaster recovery completed. Verify application functionality."
```

**2. Application-Only Recovery**:
```bash
#!/bin/bash
# app-recovery.sh

# Rollback to previous working image
kubectl set image deployment/webapp-deployment webapp=$ECR_REGISTRY/clo835-webapp:last-known-good -n clo835

# Restart deployments
kubectl rollout restart deployment/webapp-deployment -n clo835
kubectl rollout restart deployment/mysql-deployment -n clo835

# Wait for rollout to complete
kubectl rollout status deployment/webapp-deployment -n clo835
kubectl rollout status deployment/mysql-deployment -n clo835

echo "Application recovery completed"
```

## Scaling and Performance

### Horizontal Pod Autoscaler (HPA)

**1. HPA Configuration**:
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
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 100
        periodSeconds: 15
      - type: Pods
        value: 4
        periodSeconds: 15
      selectPolicy: Max
```

**2. Vertical Pod Autoscaler (VPA)**:
```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: webapp-vpa
  namespace: clo835
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: webapp-deployment
  updatePolicy:
    updateMode: "Auto"
  resourcePolicy:
    containerPolicies:
    - containerName: webapp
      minAllowed:
        cpu: 100m
        memory: 128Mi
      maxAllowed:
        cpu: 1
        memory: 1Gi
      controlledResources: ["cpu", "memory"]
```

### Cluster Autoscaler

**1. Cluster Autoscaler Deployment**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cluster-autoscaler
  namespace: kube-system
spec:
  selector:
    matchLabels:
      app: cluster-autoscaler
  template:
    metadata:
      labels:
        app: cluster-autoscaler
    spec:
      serviceAccountName: cluster-autoscaler
      containers:
      - image: k8s.gcr.io/autoscaling/cluster-autoscaler:v1.21.2
        name: cluster-autoscaler
        resources:
          limits:
            cpu: 100m
            memory: 300Mi
          requests:
            cpu: 100m
            memory: 300Mi
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
        - --scale-down-delay-after-delete=10s
        - --scale-down-delay-after-failure=3m
        - --scale-down-utilization-threshold=0.5
        env:
        - name: AWS_REGION
          value: us-east-1
```

### Performance Optimization

**1. Database Performance Tuning**:
```sql
-- MySQL performance optimization queries
-- Check slow queries
SELECT * FROM information_schema.PROCESSLIST WHERE COMMAND != 'Sleep';

-- Optimize tables
OPTIMIZE TABLE employee;

-- Check index usage
SHOW INDEX FROM employee;

-- Performance monitoring
SHOW GLOBAL STATUS LIKE 'Slow_queries';
SHOW GLOBAL STATUS LIKE 'Connections';
SHOW GLOBAL STATUS LIKE 'Threads_connected';
```

**2. Application Performance Monitoring**:
```python
# Add to Flask application for performance monitoring
import time
from functools import wraps

def monitor_performance(f):
    @wraps(f)
    def decorated_function(*args, **kwargs):
        start_time = time.time()
        result = f(*args, **kwargs)
        end_time = time.time()
        
        logger.info(f"Function {f.__name__} took {end_time - start_time:.2f} seconds")
        return result
    return decorated_function

@app.route("/")
@monitor_performance
def home():
    # Existing home function
    pass
```

## Security Maintenance

### Security Updates

**1. Regular Security Scanning**:
```bash
#!/bin/bash
# security-scan.sh

# Scan ECR images for vulnerabilities
aws ecr start-image-scan --repository-name clo835-webapp --image-id imageTag=latest

# Get scan results
aws ecr describe-image-scan-findings --repository-name clo835-webapp --image-id imageTag=latest

# Scan Kubernetes manifests
kubesec scan k8s-manifests/*.yaml

# Check for security policies
kubectl get psp,networkpolicies -A
```

**2. Certificate Management**:
```bash
#!/bin/bash
# cert-check.sh

# Check LoadBalancer certificate expiration
kubectl get ingress -A -o jsonpath='{.items[*].metadata.annotations.cert-manager\.io/cluster-issuer}'

# Check service certificates
openssl s_client -connect $(kubectl get svc webapp-service -n clo835 -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'):443 -servername $(kubectl get svc webapp-service -n clo835 -o jsonpath='{.status.loadBalancer.ingress[0].hostname}') 2>/dev/null | openssl x509 -noout -dates
```

**3. Access Review**:
```bash
#!/bin/bash
# access-review.sh

# Review RBAC permissions
kubectl auth can-i --list --as=system:serviceaccount:clo835:clo835-sa -n clo835

# Check service account usage
kubectl get pods -n clo835 -o jsonpath='{.items[*].spec.serviceAccountName}' | tr ' ' '\n' | sort | uniq

# Review IAM permissions
aws iam list-attached-role-policies --role-name clo835-node-group-role
aws iam list-attached-role-policies --role-name clo835-cluster-role
```

### Secrets Rotation

**1. Database Password Rotation**:
```bash
#!/bin/bash
# rotate-db-password.sh

# Generate new password
NEW_PASSWORD=$(openssl rand -base64 32)

# Update MySQL password
kubectl exec -n clo835 deployment/mysql-deployment -- \
  mysql -u root -p$OLD_PASSWORD -e "ALTER USER 'root'@'%' IDENTIFIED BY '$NEW_PASSWORD';"

# Update Kubernetes secret
kubectl patch secret mysql-secret -n clo835 \
  -p='{"data":{"DBPWD":"'$(echo -n $NEW_PASSWORD | base64)'"}}'

# Restart webapp to pick up new password
kubectl rollout restart deployment/webapp-deployment -n clo835
```

**2. AWS Credentials Rotation**:
```bash
#!/bin/bash
# rotate-aws-creds.sh

# Create new access key
NEW_KEYS=$(aws iam create-access-key --user-name clo835-service-user --output json)
NEW_ACCESS_KEY=$(echo $NEW_KEYS | jq -r '.AccessKey.AccessKeyId')
NEW_SECRET_KEY=$(echo $NEW_KEYS | jq -r '.AccessKey.SecretAccessKey')

# Update Kubernetes secret
kubectl patch secret aws-secret -n clo835 \
  -p='{"data":{"AWS_ACCESS_KEY_ID":"'$(echo -n $NEW_ACCESS_KEY | base64)'","AWS_SECRET_ACCESS_KEY":"'$(echo -n $NEW_SECRET_KEY | base64)'"}}'

# Restart pods to pick up new credentials
kubectl rollout restart deployment/webapp-deployment -n clo835

# Delete old access key after verification
# aws iam delete-access-key --access-key-id $OLD_ACCESS_KEY --user-name clo835-service-user
```

## Cost Management

### Cost Monitoring

**1. Daily Cost Report**:
```bash
#!/bin/bash
# daily-cost-report.sh

# Get current month costs by service
aws ce get-cost-and-usage \
  --time-period Start=$(date +%Y-%m-01),End=$(date +%Y-%m-%d) \
  --granularity DAILY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --filter file://cost-filter.json

# Cost filter file (cost-filter.json)
cat > cost-filter.json << EOF
{
  "Tags": {
    "Key": "Project",
    "Values": ["CLO835"]
  }
}
EOF
```

**2. Resource Optimization**:
```bash
#!/bin/bash
# optimize-resources.sh

# Check for oversized pods
kubectl top pods -n clo835 --sort-by=memory
kubectl top pods -n clo835 --sort-by=cpu

# Identify unused resources
kubectl get pvc -n clo835 | grep -v 'Bound'
kubectl get pv | grep -v 'Bound'

# Check for zombie nodes
kubectl get nodes | grep 'NotReady\|SchedulingDisabled'
```

### Automated Cost Controls

**1. Schedule-Based Scaling**:
```yaml
# Development environment shutdown schedule
apiVersion: batch/v1
kind: CronJob
metadata:
  name: scale-down-dev
  namespace: clo835
spec:
  schedule: "0 18 * * 1-5"  # 6 PM weekdays
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: scale-down
            image: bitnami/kubectl:latest
            command:
            - /bin/bash
            - -c
            - |
              kubectl scale deployment webapp-deployment --replicas=0 -n clo835
              kubectl scale deployment mysql-deployment --replicas=0 -n clo835
          restartPolicy: OnFailure

---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: scale-up-dev
  namespace: clo835
spec:
  schedule: "0 8 * * 1-5"  # 8 AM weekdays
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: scale-up
            image: bitnami/kubectl:latest
            command:
            - /bin/bash
            - -c
            - |
              kubectl scale deployment mysql-deployment --replicas=1 -n clo835
              sleep 30
              kubectl scale deployment webapp-deployment --replicas=1 -n clo835
          restartPolicy: OnFailure
```

## Troubleshooting

### Common Issues and Solutions

**1. Pod Startup Issues**:
```bash
# Diagnostic commands
kubectl describe pod <pod-name> -n clo835
kubectl logs <pod-name> -n clo835 --previous
kubectl get events -n clo835 --sort-by='.lastTimestamp'

# Common fixes
kubectl delete pod <pod-name> -n clo835  # Force restart
kubectl rollout restart deployment/webapp-deployment -n clo835  # Rolling restart
```

**2. Database Connection Issues**:
```bash
# Test database connectivity
kubectl exec -it deployment/webapp-deployment -n clo835 -- nc -zv mysql-service 3306

# Check MySQL logs
kubectl logs deployment/mysql-deployment -n clo835

# Reset connections
kubectl exec -it deployment/mysql-deployment -n clo835 -- mysql -u root -p -e "SHOW PROCESSLIST;"
kubectl exec -it deployment/mysql-deployment -n clo835 -- mysql -u root -p -e "KILL <connection_id>;"
```

**3. LoadBalancer Issues**:
```bash
# Check LoadBalancer status
kubectl describe svc webapp-service -n clo835

# Check AWS Load Balancer
aws elbv2 describe-load-balancers | grep clo835

# Check target group health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
```

### Emergency Procedures

**1. Application Outage Response**:
```bash
#!/bin/bash
# emergency-response.sh

echo "CLO835 Emergency Response Initiated"

# Step 1: Quick health check
kubectl get pods -n clo835
kubectl get svc -n clo835

# Step 2: Check recent events
kubectl get events -n clo835 --sort-by='.lastTimestamp' | tail -20

# Step 3: Restart if needed
if [[ $(kubectl get pods -n clo835 | grep -c "Running") -lt 2 ]]; then
  echo "Restarting deployments..."
  kubectl rollout restart deployment/mysql-deployment -n clo835
  kubectl rollout restart deployment/webapp-deployment -n clo835
fi

# Step 4: Verify recovery
kubectl wait --for=condition=available --timeout=300s deployment/webapp-deployment -n clo835
```

## Regular Maintenance Tasks

### Daily Tasks

```bash
#!/bin/bash
# daily-maintenance.sh

# Check cluster health
kubectl get nodes
kubectl get pods -n clo835

# Check resource usage
kubectl top nodes
kubectl top pods -n clo835

# Check logs for errors
kubectl logs -l app=webapp -n clo835 --since=24h | grep -i error
kubectl logs -l app=mysql -n clo835 --since=24h | grep -i error

# Check costs
aws ce get-cost-and-usage --time-period Start=$(date +%Y-%m-%d),End=$(date +%Y-%m-%d) --granularity DAILY --metrics BlendedCost
```

### Weekly Tasks

```bash
#!/bin/bash
# weekly-maintenance.sh

# Update security patches
kubectl get pods -n clo835 -o jsonpath='{.items[*].spec.containers[*].image}' | tr ' ' '\n' | sort | uniq

# Clean up old images
docker system prune -f
aws ecr list-images --repository-name clo835-webapp --filter tagStatus=UNTAGGED --query 'imageIds[?imageDigest!=null]' --output json | aws ecr batch-delete-image --repository-name clo835-webapp --image-ids file:///dev/stdin

# Backup verification
aws ec2 describe-snapshots --owner-ids self --filters "Name=tag:Project,Values=CLO835" | grep StartTime

# Performance review
kubectl top pods -n clo835 --sort-by=cpu
kubectl top pods -n clo835 --sort-by=memory
```

### Monthly Tasks

```bash
#!/bin/bash
# monthly-maintenance.sh

# Security audit
./security-scan.sh

# Cost optimization review
aws ce get-cost-and-usage --time-period Start=$(date -d 'last month' +%Y-%m-01),End=$(date +%Y-%m-01) --granularity MONTHLY --metrics BlendedCost --group-by Type=DIMENSION,Key=SERVICE

# Capacity planning
kubectl describe nodes | grep -A 5 "Allocated resources"

# Update documentation
git add docs/
git commit -m "Monthly documentation update"
git push
```

---

**Note**: This maintenance guide should be adapted based on your specific operational requirements, team structure, and organizational policies. Regular review and updates of these procedures ensure continued effectiveness in maintaining the CLO835 infrastructure.