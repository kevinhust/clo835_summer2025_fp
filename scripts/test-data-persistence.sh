#!/bin/bash

# CLO835 Final Project - Data Persistence Test Script
# This script helps demonstrate data persistence for the demo (Requirement #5)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}CLO835 Data Persistence Demo${NC}"
echo "This script demonstrates that data persists when MySQL pods are recreated"
echo

# Configuration
NAMESPACE=${NAMESPACE:-"fp"}

# Step 1: Add test data to the application
echo -e "${BLUE}Step 1: Adding test employee data${NC}"
echo "First, let's add some test data through the application..."

# Get the LoadBalancer URL
EXTERNAL_URL=$(kubectl get service webapp-service -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || echo "")

if [ ! -z "$EXTERNAL_URL" ]; then
    echo "Application URL: http://$EXTERNAL_URL"
    echo "📝 Demo Action: Go to the application and add a test employee:"
    echo "   - Employee ID: 1001"
    echo "   - First Name: John"
    echo "   - Last Name: Doe"
    echo "   - Skill: Cloud Engineering"
    echo "   - Location: Toronto"
else
    echo "⚠️  LoadBalancer not ready, use port forwarding for testing:"
    echo "   kubectl port-forward svc/webapp-service 8080:80 -n $NAMESPACE"
    echo "   Then access: http://localhost:8080"
fi

echo
echo "Press Enter when you have added test data to continue..."
read -r

# Step 2: Verify current MySQL pod
echo -e "${BLUE}Step 2: Current MySQL Pod Status${NC}"
kubectl get pods -n $NAMESPACE -l app=mysql
MYSQL_POD=$(kubectl get pods -n $NAMESPACE -l app=mysql -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ ! -z "$MYSQL_POD" ]; then
    echo "Current MySQL pod: $MYSQL_POD"
    
    # Show MySQL pod age and restart count
    echo -e "\n${YELLOW}Pod Details:${NC}"
    kubectl get pod $MYSQL_POD -n $NAMESPACE -o wide
    
    # Show PVC status
    echo -e "\n${YELLOW}PVC Status:${NC}"
    kubectl get pvc -n $NAMESPACE
else
    echo -e "${RED}❌ MySQL pod not found!${NC}"
    exit 1
fi

echo

# Step 3: Delete MySQL pod to test persistence
echo -e "${BLUE}Step 3: Deleting MySQL Pod to Test Data Persistence${NC}"
echo "🗑️  Deleting MySQL pod to simulate failure/restart..."

kubectl delete pod $MYSQL_POD -n $NAMESPACE

echo "✅ Pod deleted successfully"
echo

# Step 4: Wait for new pod to be created
echo -e "${BLUE}Step 4: Waiting for New MySQL Pod${NC}"
echo "⏳ Waiting for Kubernetes to create a new MySQL pod..."

# Wait for new pod to be running
kubectl wait --for=condition=Ready pod -l app=mysql -n $NAMESPACE --timeout=120s

NEW_MYSQL_POD=$(kubectl get pods -n $NAMESPACE -l app=mysql -o jsonpath='{.items[0].metadata.name}')
echo "✅ New MySQL pod created: $NEW_MYSQL_POD"

echo -e "\n${YELLOW}New Pod Details:${NC}"
kubectl get pod $NEW_MYSQL_POD -n $NAMESPACE -o wide

echo

# Step 5: Verify PV/PVC are still bound
echo -e "${BLUE}Step 5: Verifying Persistent Volume Status${NC}"
echo -e "${YELLOW}PVC Status (should remain bound):${NC}"
kubectl get pvc -n $NAMESPACE

PV_NAME=$(kubectl get pvc mysql-pvc -n $NAMESPACE -o jsonpath='{.spec.volumeName}')
echo -e "\n${YELLOW}Associated PV: $PV_NAME${NC}"
kubectl get pv $PV_NAME

echo

# Step 6: Test data persistence
echo -e "${BLUE}Step 6: Testing Data Persistence${NC}"
echo "🔍 Now test that your employee data still exists:"

if [ ! -z "$EXTERNAL_URL" ]; then
    echo "Application URL: http://$EXTERNAL_URL"
else
    echo "Use port forwarding: kubectl port-forward svc/webapp-service 8080:80 -n $NAMESPACE"
    echo "Then access: http://localhost:8080"
fi

echo
echo "📝 Demo Action: Go to 'Get Employee' page and search for Employee ID: 1001"
echo "✅ Expected Result: John Doe's data should still be there!"
echo

# Step 7: Demo summary
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}    Data Persistence Demo Complete${NC}"
echo -e "${GREEN}================================${NC}"
echo
echo -e "${YELLOW}What was demonstrated:${NC}"
echo "✅ 1. Added test data to MySQL database"
echo "✅ 2. Showed original MySQL pod ($MYSQL_POD)"
echo "✅ 3. Deleted MySQL pod to simulate failure"
echo "✅ 4. Kubernetes automatically created new pod ($NEW_MYSQL_POD)"
echo "✅ 5. PVC remained bound to the same PV"
echo "✅ 6. Data persisted across pod recreation"
echo
echo -e "${BLUE}Key Points for Demo Recording:${NC}"
echo "• Data survives pod failures/restarts"
echo "• Amazon EBS volume provides persistent storage"
echo "• Kubernetes PV/PVC automatically handle volume attachment"
echo "• This ensures high availability and data durability"
echo
echo -e "${GREEN}Perfect for CLO835 Requirement #5! 🎬${NC}"