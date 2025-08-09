# 03 - Demo Cleanup Phase

## Overview
After completing your CLO835 Final Project demonstration, it's **CRITICAL** to clean up all AWS resources to avoid unexpected charges. This guide provides both quick cleanup for immediate cost savings and thorough cleanup for complete resource removal.

⚠️ **IMPORTANT**: AWS charges continue until resources are deleted. Follow this cleanup immediately after your demo.

💰 **Estimated Cost Savings**: ~$50-100/month by properly cleaning up EKS and associated resources.

## Quick Emergency Cleanup (5 minutes)

If you're in a hurry and need to stop charges immediately:

```bash
# Load environment variables
source /tmp/demo-env.sh

# 1. Delete EKS cluster (MOST EXPENSIVE - do this first!)
eksctl delete cluster --name $CLUSTER_NAME --region $AWS_REGION

# 2. Delete ECR repository
aws ecr delete-repository --repository-name $ECR_REPOSITORY --region $AWS_REGION --force

# 3. Delete S3 bucket
aws s3 rb s3://$S3_BUCKET --force
```

⏰ **Note**: EKS deletion takes 10-15 minutes but stops charges immediately when initiated.

## Thorough Cleanup (15 minutes)

For complete cleanup and verification that nothing is left behind:

### Phase 1: Kubernetes Resources Cleanup

```bash
# Load environment variables if not already loaded
source /tmp/demo-env.sh

# Delete all application resources from Kubernetes
kubectl delete all --all -n $NAMESPACE

# Delete namespace (this also deletes PVCs and PVs)
kubectl delete namespace $NAMESPACE

# Verify namespace deletion
kubectl get namespaces | grep -v $NAMESPACE || echo "Namespace $NAMESPACE successfully deleted"

# Delete any remaining persistent volumes
kubectl delete pv --all

# Clean up any hanging pods or resources
kubectl get all --all-namespaces | grep -i $NAMESPACE || echo "All namespace resources cleaned up"
```

### Phase 2: AWS LoadBalancer Cleanup

```bash
# Check for any remaining LoadBalancers (these can be expensive!)
aws elbv2 describe-load-balancers --region $AWS_REGION --query 'LoadBalancers[?contains(LoadBalancerName, `k8s`) || contains(Tags[?Key==`kubernetes.io/cluster/clo835-eks-cluster`].Value, `owned`)].LoadBalancerArn' --output text

# If any LoadBalancers are found, note their ARNs and delete them manually:
# aws elbv2 delete-load-balancer --load-balancer-arn <ARN>

# Check for remaining target groups
aws elbv2 describe-target-groups --region $AWS_REGION --query 'TargetGroups[?contains(TargetGroupName, `k8s`)].TargetGroupArn' --output text

# Delete target groups if found:
# aws elbv2 delete-target-group --target-group-arn <ARN>
```

### Phase 3: EKS Cluster Cleanup

```bash
# Delete the EKS cluster and all associated resources
echo "Deleting EKS cluster... This will take 10-15 minutes."
eksctl delete cluster --name $CLUSTER_NAME --region $AWS_REGION

# This command will automatically clean up:
# - EKS cluster control plane
# - Worker node groups  
# - Associated security groups
# - IAM roles created by eksctl
# - VPC and subnets (if created by eksctl)
```

### Phase 4: Container Registry Cleanup

```bash
# Delete all images in ECR repository first
aws ecr list-images --repository-name $ECR_REPOSITORY --region $AWS_REGION --query 'imageIds[*]' --output json > /tmp/images.json

# Delete all images (if any exist)
if [ -s /tmp/images.json ] && [ "$(cat /tmp/images.json)" != "[]" ]; then
    aws ecr batch-delete-image --repository-name $ECR_REPOSITORY --region $AWS_REGION --image-ids file:///tmp/images.json
    echo "Deleted all images from ECR repository"
else
    echo "No images found in ECR repository"
fi

# Delete ECR repository
aws ecr delete-repository --repository-name $ECR_REPOSITORY --region $AWS_REGION --force
echo "ECR repository $ECR_REPOSITORY deleted"

# Clean up temp file
rm -f /tmp/images.json
```

### Phase 5: S3 Storage Cleanup

```bash
# List all objects in S3 bucket before deletion
echo "Contents of S3 bucket before deletion:"
aws s3 ls s3://$S3_BUCKET --recursive --human-readable

# Delete all objects in the bucket
aws s3 rm s3://$S3_BUCKET --recursive

# Delete the bucket itself
aws s3 rb s3://$S3_BUCKET

echo "S3 bucket $S3_BUCKET and all contents deleted"
```

### Phase 6: Verify Complete Cleanup

```bash
# 1. Verify EKS cluster is gone
aws eks describe-cluster --name $CLUSTER_NAME --region $AWS_REGION 2>/dev/null && echo "❌ EKS cluster still exists!" || echo "✅ EKS cluster deleted"

# 2. Verify ECR repository is gone  
aws ecr describe-repositories --repository-names $ECR_REPOSITORY --region $AWS_REGION 2>/dev/null && echo "❌ ECR repository still exists!" || echo "✅ ECR repository deleted"

# 3. Verify S3 bucket is gone
aws s3 ls s3://$S3_BUCKET 2>/dev/null && echo "❌ S3 bucket still exists!" || echo "✅ S3 bucket deleted"

# 4. Check for any remaining LoadBalancers
REMAINING_LB=$(aws elbv2 describe-load-balancers --region $AWS_REGION --query 'LoadBalancers[?contains(Tags[?Key==`kubernetes.io/cluster/'$CLUSTER_NAME'`].Value, `owned`)].LoadBalancerArn' --output text)
if [ -n "$REMAINING_LB" ]; then
    echo "❌ WARNING: LoadBalancers still exist: $REMAINING_LB"
    echo "   Manual deletion required: aws elbv2 delete-load-balancer --load-balancer-arn <ARN>"
else
    echo "✅ No remaining LoadBalancers"
fi

# 5. Check kubeconfig cleanup
kubectl config get-contexts | grep $CLUSTER_NAME && echo "❌ Kubeconfig still contains cluster reference" || echo "✅ Kubeconfig clean"

# Clean up kubeconfig if needed
kubectl config delete-context $(kubectl config get-contexts -o name | grep $CLUSTER_NAME) 2>/dev/null || true
kubectl config delete-cluster $CLUSTER_NAME 2>/dev/null || true
```

## Cost Verification

### Check Your AWS Bill

```bash
# Get AWS cost information for today (requires Cost Explorer permissions)
TODAY=$(date +%Y-%m-%d)
aws ce get-cost-and-usage \
    --time-period Start=$TODAY,End=$TODAY \
    --granularity DAILY \
    --metrics BlendedCost \
    --group-by Type=DIMENSION,Key=SERVICE \
    --region $AWS_REGION 2>/dev/null || echo "Note: Cost Explorer access may be restricted"

echo ""
echo "💡 To monitor costs:"
echo "1. Visit AWS Cost Explorer: https://console.aws.amazon.com/cost-management/home"
echo "2. Check EC2 instances (EKS nodes): https://console.aws.amazon.com/ec2/v2/home?region=$AWS_REGION#Instances:"
echo "3. Check Load Balancers: https://console.aws.amazon.com/ec2/v2/home?region=$AWS_REGION#LoadBalancers:"
```

## Local Cleanup

```bash
# Clean up local Docker images
docker rmi webapp:latest 2>/dev/null || echo "Local webapp image already removed"
docker rmi $ECR_URI:latest 2>/dev/null || echo "ECR image already removed"

# Clean up local demo files
rm -f /tmp/demo-env.sh
rm -rf demo-images/ 2>/dev/null || echo "No local demo-images directory"

# Docker system cleanup (optional - removes all unused images/containers)
# docker system prune -f
```

## Manual Cleanup Verification

### AWS Console Checks

Visit these AWS Console pages to manually verify cleanup:

1. **EKS Clusters**: https://console.aws.amazon.com/eks/home?region=us-east-1#clusters
   - Should show no clusters named `clo835-eks-cluster`

2. **EC2 Instances**: https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#Instances
   - Should show no instances with `clo835` or `eks` in the name

3. **Load Balancers**: https://console.aws.amazon.com/ec2/v2/home?region=us-east-1#LoadBalancers
   - Should show no LBs created by Kubernetes (usually named `k8s-*`)

4. **ECR Repositories**: https://console.aws.amazon.com/ecr/repositories?region=us-east-1
   - Should show no repository named `clo835fp-webapp`

5. **S3 Buckets**: https://s3.console.aws.amazon.com/s3/home?region=us-east-1
   - Should show no bucket named `clo835fp-bg-images`

6. **VPC**: https://console.aws.amazon.com/vpc/home?region=us-east-1#vpcs
   - If eksctl created VPC, it should be gone. Check for VPCs with `eksctl` in name.

## Common Cleanup Issues & Solutions

### EKS Cluster Won't Delete

```bash
# Force delete if stuck
eksctl delete cluster --name $CLUSTER_NAME --region $AWS_REGION --force

# If still stuck, delete nodegroups first
eksctl delete nodegroup --cluster=$CLUSTER_NAME --name=clo835-nodes --region=$AWS_REGION
```

### LoadBalancer Still Exists

```bash
# Find all LoadBalancers with tags
aws elbv2 describe-load-balancers --region $AWS_REGION --query 'LoadBalancers[*].LoadBalancerArn' --output text | while read arn; do
  if aws elbv2 describe-tags --resource-arns $arn --region $AWS_REGION --query 'TagDescriptions[0].Tags[?Key==`kubernetes.io/cluster/'$CLUSTER_NAME'`]' --output text | grep -q owned; then
    echo "Deleting LoadBalancer: $arn"
    aws elbv2 delete-load-balancer --load-balancer-arn $arn --region $AWS_REGION
  fi
done
```

### S3 Bucket Won't Delete

```bash
# Force delete all object versions (if versioning enabled)
aws s3api list-object-versions --bucket $S3_BUCKET --query 'Versions[].{Key:Key,VersionId:VersionId}' --output json | \
jq -r '.[] | "\(.Key) \(.VersionId)"' | \
while read key version; do
  aws s3api delete-object --bucket $S3_BUCKET --key "$key" --version-id "$version"
done

# Then delete bucket
aws s3 rb s3://$S3_BUCKET --force
```

## Cleanup Verification Checklist

- [ ] EKS cluster deleted (`eksctl get clusters` shows none)
- [ ] EC2 instances terminated (no instances with `clo835` or `eks`)  
- [ ] LoadBalancers deleted (no `k8s-*` LoadBalancers)
- [ ] ECR repository deleted
- [ ] S3 bucket and contents deleted
- [ ] Local Docker images removed
- [ ] Kubeconfig cleaned up
- [ ] AWS Console shows no related resources

## Final Cost Check

**24 hours after cleanup**, verify in AWS Cost Explorer that:
- No new charges for EKS
- No new charges for EC2 instances  
- No new charges for LoadBalancer
- Minimal/zero charges for S3 and ECR

💡 **Pro Tip**: Set up a AWS Budget alert for $1 to catch any unexpected charges from missed resources.

---

✅ **Cleanup Complete!**

Your AWS account should now be clean with no ongoing charges from the CLO835 Final Project demo.

**Cost Impact**: You've avoided approximately $50-100/month in charges by properly cleaning up the EKS cluster and associated resources.