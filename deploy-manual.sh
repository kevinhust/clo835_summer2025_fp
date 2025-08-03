#!/bin/bash

# Manual deployment script for CLO835 Final Project
# This script can be used for manual deployments when CI/CD is not available

set -e

# Configuration
AWS_REGION=${AWS_REGION:-us-east-1}
ECR_REPOSITORY=${ECR_REPOSITORY:-clo835-webapp}
EKS_CLUSTER_NAME=${EKS_CLUSTER_NAME:-clo835-cluster}
NAMESPACE=${NAMESPACE:-clo835}
IMAGE_TAG=${IMAGE_TAG:-$(git rev-parse --short HEAD)}

echo "🚀 Starting manual deployment..."
echo "Region: $AWS_REGION"
echo "Repository: $ECR_REPOSITORY"
echo "Cluster: $EKS_CLUSTER_NAME"
echo "Namespace: $NAMESPACE"
echo "Image Tag: $IMAGE_TAG"

# Check prerequisites
echo "📋 Checking prerequisites..."
command -v aws >/dev/null 2>&1 || { echo "❌ AWS CLI is required but not installed. Aborting." >&2; exit 1; }
command -v docker >/dev/null 2>&1 || { echo "❌ Docker is required but not installed. Aborting." >&2; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo "❌ kubectl is required but not installed. Aborting." >&2; exit 1; }

# Verify AWS credentials
echo "🔐 Verifying AWS credentials..."
aws sts get-caller-identity > /dev/null || { echo "❌ AWS credentials not configured. Aborting." >&2; exit 1; }

# Get ECR repository URI
echo "📦 Getting ECR repository URI..."
ECR_URI=$(aws ecr describe-repositories --repository-names $ECR_REPOSITORY --region $AWS_REGION --query 'repositories[0].repositoryUri' --output text)
if [ "$ECR_URI" == "None" ] || [ -z "$ECR_URI" ]; then
    echo "❌ ECR repository $ECR_REPOSITORY not found. Creating it..."
    aws ecr create-repository --repository-name $ECR_REPOSITORY --region $AWS_REGION
    ECR_URI=$(aws ecr describe-repositories --repository-names $ECR_REPOSITORY --region $AWS_REGION --query 'repositories[0].repositoryUri' --output text)
fi
echo "ECR URI: $ECR_URI"

# Login to ECR
echo "🔑 Logging into ECR..."
aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $ECR_URI

# Run tests
echo "🧪 Running tests..."
if [ -d "tests" ]; then
    python -m pytest tests/ -v || { echo "❌ Tests failed. Aborting deployment." >&2; exit 1; }
    echo "✅ All tests passed!"
else
    echo "⚠️  No tests directory found. Skipping tests."
fi

# Build Docker image
echo "🏗️  Building Docker image..."
docker build -t $ECR_REPOSITORY:$IMAGE_TAG .
docker tag $ECR_REPOSITORY:$IMAGE_TAG $ECR_URI:$IMAGE_TAG
docker tag $ECR_REPOSITORY:$IMAGE_TAG $ECR_URI:latest

# Push to ECR
echo "📤 Pushing image to ECR..."
docker push $ECR_URI:$IMAGE_TAG
docker push $ECR_URI:latest

# Update kubeconfig
echo "⚙️  Updating kubeconfig for EKS..."
aws eks update-kubeconfig --region $AWS_REGION --name $EKS_CLUSTER_NAME

# Apply Kubernetes manifests
echo "☸️  Applying Kubernetes manifests..."
kubectl apply -f k8s-manifests/

# Update deployment image
echo "🔄 Updating deployment with new image..."
kubectl set image deployment/webapp webapp=$ECR_URI:$IMAGE_TAG -n $NAMESPACE

# Wait for rollout
echo "⏳ Waiting for deployment rollout..."
kubectl rollout status deployment/webapp -n $NAMESPACE --timeout=300s

# Verify deployment
echo "✅ Verifying deployment..."
kubectl get pods -n $NAMESPACE
kubectl get services -n $NAMESPACE

# Get service URL
echo "🌐 Getting service information..."
SERVICE_TYPE=$(kubectl get svc webapp-service -n $NAMESPACE -o jsonpath='{.spec.type}')
if [ "$SERVICE_TYPE" == "LoadBalancer" ]; then
    echo "Waiting for LoadBalancer external IP..."
    kubectl wait --for=jsonpath='{.status.loadBalancer.ingress}' service/webapp-service -n $NAMESPACE --timeout=300s
    EXTERNAL_IP=$(kubectl get svc webapp-service -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    if [ -z "$EXTERNAL_IP" ]; then
        EXTERNAL_IP=$(kubectl get svc webapp-service -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    fi
    echo "🎉 Application deployed successfully!"
    echo "🔗 Access your application at: http://$EXTERNAL_IP"
else
    NODEPORT=$(kubectl get svc webapp-service -n $NAMESPACE -o jsonpath='{.spec.ports[0].nodePort}')
    echo "🎉 Application deployed successfully!"
    echo "🔗 Service type: $SERVICE_TYPE"
    if [ "$SERVICE_TYPE" == "NodePort" ]; then
        echo "🔗 Access via NodePort: $NODEPORT"
        echo "💡 Use 'kubectl port-forward svc/webapp-service 8080:80 -n $NAMESPACE' for local access"
    fi
fi

# Health check
echo "🏥 Running health check..."
kubectl exec -n $NAMESPACE deployment/webapp -- curl -f http://localhost:81/about || echo "⚠️  Health check failed, but deployment completed"

echo "✅ Manual deployment completed successfully!"
echo "📊 Deployment summary:"
echo "   - Image: $ECR_URI:$IMAGE_TAG"
echo "   - Namespace: $NAMESPACE"
echo "   - Cluster: $EKS_CLUSTER_NAME"
echo "   - Region: $AWS_REGION"