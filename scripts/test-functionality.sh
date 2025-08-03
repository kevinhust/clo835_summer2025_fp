#!/bin/bash

# CLO835 Final Project - Functionality Testing Script
# This script tests all required functionality for the final project

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="clo835"
AWS_REGION="${AWS_REGION:-us-east-1}"
TEST_TIMEOUT=60

# Logging functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

success() {
    echo -e "${GREEN}✓ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

error() {
    echo -e "${RED}✗ $1${NC}"
}

# Test results tracking
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"
    
    ((TESTS_TOTAL++))
    log "Running test: $test_name"
    
    if eval "$test_command"; then
        success "PASSED: $test_name"
        ((TESTS_PASSED++))
        return 0
    else
        error "FAILED: $test_name"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Test 1: Verify namespace exists
test_namespace() {
    kubectl get namespace $NAMESPACE &> /dev/null
}

# Test 2: Verify all pods are running
test_pods_running() {
    local not_running=$(kubectl get pods -n $NAMESPACE --field-selector=status.phase!=Running --no-headers 2>/dev/null | wc -l)
    [ "$not_running" -eq 0 ]
}

# Test 3: Verify MySQL deployment is ready
test_mysql_deployment() {
    kubectl get deployment mysql-deployment -n $NAMESPACE &> /dev/null &&
    [ "$(kubectl get deployment mysql-deployment -n $NAMESPACE -o jsonpath='{.status.readyReplicas}')" -eq 1 ]
}

# Test 4: Verify webapp deployment is ready
test_webapp_deployment() {
    kubectl get deployment webapp-deployment -n $NAMESPACE &> /dev/null &&
    [ "$(kubectl get deployment webapp-deployment -n $NAMESPACE -o jsonpath='{.status.readyReplicas}')" -eq 1 ]
}

# Test 5: Verify MySQL service exists and has endpoints
test_mysql_service() {
    kubectl get service mysql-service -n $NAMESPACE &> /dev/null &&
    [ -n "$(kubectl get endpoints mysql-service -n $NAMESPACE -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null)" ]
}

# Test 6: Verify webapp service exists and has endpoints
test_webapp_service() {
    kubectl get service webapp-service -n $NAMESPACE &> /dev/null &&
    [ -n "$(kubectl get endpoints webapp-service -n $NAMESPACE -o jsonpath='{.subsets[0].addresses[0].ip}' 2>/dev/null)" ]
}

# Test 7: Verify LoadBalancer service has external access
test_loadbalancer_access() {
    local external_ip=$(kubectl get service webapp-service -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
    if [ -n "$external_ip" ] && [ "$external_ip" != "null" ]; then
        # Test if the service is accessible
        timeout $TEST_TIMEOUT curl -f -s "http://$external_ip" > /dev/null
    else
        return 1
    fi
}

# Test 8: Verify PVC is bound
test_pvc_bound() {
    local pvc_status=$(kubectl get pvc mysql-pvc -n $NAMESPACE -o jsonpath='{.status.phase}' 2>/dev/null)
    [ "$pvc_status" = "Bound" ]
}

# Test 9: Verify ConfigMap exists and has expected data
test_configmap() {
    kubectl get configmap webapp-config -n $NAMESPACE &> /dev/null &&
    [ -n "$(kubectl get configmap webapp-config -n $NAMESPACE -o jsonpath='{.data.BACKGROUND_IMAGE_URL}' 2>/dev/null)" ]
}

# Test 10: Verify secrets exist
test_secrets() {
    kubectl get secret mysql-secret -n $NAMESPACE &> /dev/null &&
    kubectl get secret aws-secret -n $NAMESPACE &> /dev/null
}

# Test 11: Verify RBAC resources
test_rbac() {
    kubectl get serviceaccount clo835-sa -n $NAMESPACE &> /dev/null &&
    kubectl get role clo835-role -n $NAMESPACE &> /dev/null &&
    kubectl get rolebinding clo835-rolebinding -n $NAMESPACE &> /dev/null
}

# Test 12: Database connectivity test
test_database_connectivity() {
    local mysql_pod=$(kubectl get pods -n $NAMESPACE -l app=mysql -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    if [ -n "$mysql_pod" ]; then
        kubectl exec -n $NAMESPACE "$mysql_pod" -- mysql -u root -ppassword -e "SELECT 1;" &> /dev/null
    else
        return 1
    fi
}

# Test 13: Application logs check
test_application_logs() {
    local webapp_pod=$(kubectl get pods -n $NAMESPACE -l app=webapp -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    if [ -n "$webapp_pod" ]; then
        # Check for background image URL in logs
        kubectl logs -n $NAMESPACE "$webapp_pod" | grep -q "Background image URL" &> /dev/null
    else
        return 1
    fi
}

# Test 14: S3 integration test
test_s3_integration() {
    local webapp_pod=$(kubectl get pods -n $NAMESPACE -l app=webapp -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    if [ -n "$webapp_pod" ]; then
        # Check if S3 client was initialized
        kubectl logs -n $NAMESPACE "$webapp_pod" | grep -q "S3 client initialized\|Successfully downloaded background image" &> /dev/null
    else
        return 1
    fi
}

# Test 15: Test data persistence (requires pod restart)
test_data_persistence() {
    local mysql_pod=$(kubectl get pods -n $NAMESPACE -l app=mysql -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    if [ -n "$mysql_pod" ]; then
        # Insert test data
        kubectl exec -n $NAMESPACE "$mysql_pod" -- mysql -u root -ppassword employees -e "INSERT INTO employee VALUES ('test123', 'Test', 'User', 'Testing', 'Test Location');" &> /dev/null
        
        # Delete pod to trigger restart
        kubectl delete pod -n $NAMESPACE "$mysql_pod" &> /dev/null
        
        # Wait for new pod to be ready
        kubectl wait --for=condition=ready --timeout=120s pods -l app=mysql -n $NAMESPACE &> /dev/null
        
        # Check if data persists
        local new_mysql_pod=$(kubectl get pods -n $NAMESPACE -l app=mysql -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
        if [ -n "$new_mysql_pod" ]; then
            kubectl exec -n $NAMESPACE "$new_mysql_pod" -- mysql -u root -ppassword employees -e "SELECT * FROM employee WHERE emp_id='test123';" &> /dev/null
        else
            return 1
        fi
    else
        return 1
    fi
}

# Test 16: Health check endpoints
test_health_endpoints() {
    local webapp_pod=$(kubectl get pods -n $NAMESPACE -l app=webapp -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    if [ -n "$webapp_pod" ]; then
        # Port forward to test locally
        kubectl port-forward -n $NAMESPACE "$webapp_pod" 8080:81 &> /dev/null &
        local pf_pid=$!
        sleep 5
        
        # Test if application responds
        local result=0
        curl -f -s "http://localhost:8080" > /dev/null || result=1
        
        # Cleanup port forward
        kill $pf_pid &> /dev/null || true
        
        return $result
    else
        return 1
    fi
}

# Get application URL for external testing
get_application_url() {
    local external_ip=$(kubectl get service webapp-service -n $NAMESPACE -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null)
    if [ -n "$external_ip" ] && [ "$external_ip" != "null" ]; then
        echo "http://$external_ip"
    else
        # Fallback: use port-forward for testing
        echo "localhost:8080"
    fi
}

# Display test summary
show_test_summary() {
    echo
    log "=== Test Summary ==="
    log "Tests passed: $TESTS_PASSED"
    log "Tests failed: $TESTS_FAILED"
    log "Total tests: $TESTS_TOTAL"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        success "All tests passed! ✨"
        return 0
    else
        error "Some tests failed. Please check the issues above."
        return 1
    fi
}

# Main test execution
main() {
    log "Starting CLO835 Final Project Functionality Tests..."
    echo
    
    # Check if kubectl is configured for the cluster
    if ! kubectl cluster-info &> /dev/null; then
        error "kubectl is not configured or cluster is not accessible"
        exit 1
    fi
    
    log "=== Running Infrastructure Tests ==="
    
    run_test "Namespace exists" "test_namespace"
    run_test "All pods are running" "test_pods_running"
    run_test "MySQL deployment ready" "test_mysql_deployment"
    run_test "Webapp deployment ready" "test_webapp_deployment"
    run_test "MySQL service has endpoints" "test_mysql_service"
    run_test "Webapp service has endpoints" "test_webapp_service"
    run_test "PVC is bound" "test_pvc_bound"
    run_test "ConfigMap exists with data" "test_configmap"
    run_test "Secrets exist" "test_secrets"
    run_test "RBAC resources exist" "test_rbac"
    
    echo
    log "=== Running Application Tests ==="
    
    run_test "Database connectivity" "test_database_connectivity"
    run_test "Application logs contain expected entries" "test_application_logs"
    run_test "S3 integration working" "test_s3_integration"
    run_test "Health endpoints respond" "test_health_endpoints"
    
    echo
    log "=== Running Integration Tests ==="
    
    run_test "LoadBalancer external access" "test_loadbalancer_access"
    
    echo
    log "=== Running Data Persistence Test ==="
    warning "This test will restart the MySQL pod to test data persistence..."
    
    run_test "Data persistence after pod restart" "test_data_persistence"
    
    echo
    show_test_summary
    
    # Display application access information
    echo
    log "=== Application Access Information ==="
    APP_URL=$(get_application_url)
    log "Application URL: $APP_URL"
    
    if [[ "$APP_URL" == *"localhost"* ]]; then
        warning "LoadBalancer IP not available. Use port-forward for testing:"
        warning "kubectl port-forward -n $NAMESPACE service/webapp-service 8080:80"
    fi
    
    echo
    log "=== Manual Testing Checklist ==="
    log "Please manually verify the following:"
    log "1. ✓ Application loads in browser"
    log "2. ✓ Background image displays correctly"
    log "3. ✓ Add employee functionality works"
    log "4. ✓ Get employee functionality works"
    log "5. ✓ Data persists after MySQL pod restart"
    log "6. ✓ Update ConfigMap and verify new background image"
    
    echo
    log "To test ConfigMap updates:"
    log "1. kubectl edit configmap webapp-config -n $NAMESPACE"
    log "2. Change BACKGROUND_IMAGE_URL to a new S3 image"
    log "3. Restart webapp pods: kubectl rollout restart deployment/webapp-deployment -n $NAMESPACE"
    log "4. Verify new background image appears in browser"
    
    if [ $TESTS_FAILED -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# Handle script arguments
case "${1:-}" in
    --help|-h)
        echo "CLO835 Final Project - Functionality Testing Script"
        echo
        echo "Usage: $0 [options]"
        echo
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --quick        Run only quick tests (skip data persistence)"
        echo
        echo "Environment Variables:"
        echo "  NAMESPACE      Kubernetes namespace (default: clo835)"
        echo "  AWS_REGION     AWS region (default: us-east-1)"
        echo
        exit 0
        ;;
    --quick)
        log "Running quick tests (skipping data persistence test)"
        test_data_persistence() { log "Data persistence test skipped (quick mode)"; return 0; }
        ;;
esac

# Run main testing
main