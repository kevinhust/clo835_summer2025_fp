#!/bin/bash

# Validation script for CLO835 Final Project CI/CD setup
# This script validates that all required files and configurations are in place

set -e

echo "🔍 CLO835 Final Project - CI/CD Setup Validation"
echo "================================================"

# Check if we're in the right directory
if [ ! -f "app.py" ]; then
    echo "❌ Error: app.py not found. Please run this script from the project root directory."
    exit 1
fi

echo "✅ Project root directory confirmed"

# Check GitHub Actions workflow files
echo ""
echo "📁 Checking GitHub Actions setup..."
if [ -f ".github/workflows/ci-cd.yml" ]; then
    echo "✅ Main CI/CD workflow file exists"
else
    echo "❌ Missing: .github/workflows/ci-cd.yml"
    exit 1
fi

if [ -f ".github/workflows/security-scan.yml" ]; then
    echo "✅ Security scanning workflow exists"
else
    echo "❌ Missing: .github/workflows/security-scan.yml"
    exit 1
fi

# Check Dockerfile optimization
echo ""
echo "🐳 Checking Docker setup..."
if grep -q "multi-stage" Dockerfile || grep -q "FROM.*as.*builder" Dockerfile; then
    echo "✅ Multi-stage Dockerfile detected"
else
    echo "⚠️  Warning: Dockerfile may not be using multi-stage build"
fi

if grep -q "USER appuser" Dockerfile; then
    echo "✅ Non-root user configured in Dockerfile"
else
    echo "❌ Warning: Dockerfile should run as non-root user"
fi

if grep -q "HEALTHCHECK" Dockerfile; then
    echo "✅ Health check configured in Dockerfile"
else
    echo "⚠️  Warning: No health check found in Dockerfile"
fi

# Check test setup
echo ""
echo "🧪 Checking test setup..."
if [ -d "tests" ] && [ -f "tests/test_app.py" ]; then
    echo "✅ Test directory and test files exist"
else
    echo "❌ Missing: tests directory or test files"
    exit 1
fi

if [ -f "pytest.ini" ]; then
    echo "✅ Pytest configuration exists"
else
    echo "⚠️  Warning: No pytest.ini configuration file"
fi

# Check supporting files
echo ""
echo "📄 Checking supporting files..."
if [ -f ".gitignore" ]; then
    echo "✅ .gitignore file exists"
else
    echo "❌ Missing: .gitignore file"
fi

if [ -f "README.md" ]; then
    echo "✅ README.md documentation exists"
else
    echo "❌ Missing: README.md file"
fi

if [ -f "deploy-manual.sh" ]; then
    echo "✅ Manual deployment script exists"
    if [ -x "deploy-manual.sh" ]; then
        echo "✅ Deploy script is executable"
    else
        echo "⚠️  Warning: Deploy script is not executable"
    fi
else
    echo "⚠️  Optional: Manual deployment script not found"
fi

# Check Python dependencies
echo ""
echo "🐍 Checking Python setup..."
if [ -f "requirements.txt" ]; then
    echo "✅ requirements.txt exists"
    
    # Check for key dependencies
    if grep -q "flask" requirements.txt; then
        echo "✅ Flask dependency found"
    else
        echo "❌ Missing Flask in requirements.txt"
    fi
    
    if grep -q "boto3" requirements.txt; then
        echo "✅ AWS boto3 dependency found"
    else
        echo "❌ Missing boto3 in requirements.txt"
    fi
    
    if grep -q "requests" requirements.txt; then
        echo "✅ requests dependency found (for health checks)"
    else
        echo "⚠️  Warning: requests dependency not found"
    fi
else
    echo "❌ Missing: requirements.txt file"
    exit 1
fi

# Check Kubernetes manifests
echo ""
echo "☸️  Checking Kubernetes setup..."
if [ -d "k8s-manifests" ]; then
    echo "✅ Kubernetes manifests directory exists"
    
    manifest_count=$(find k8s-manifests -name "*.yaml" | wc -l)
    echo "✅ Found $manifest_count Kubernetes manifest files"
    
    if [ -f "k8s-manifests/webapp-deployment.yaml" ]; then
        echo "✅ Webapp deployment manifest exists"
    else
        echo "❌ Missing: webapp deployment manifest"
    fi
    
    if [ -f "k8s-manifests/webapp-service.yaml" ]; then
        echo "✅ Webapp service manifest exists"
    else
        echo "❌ Missing: webapp service manifest"
    fi
else
    echo "❌ Missing: k8s-manifests directory"
fi

# Run basic syntax validation
echo ""
echo "🔧 Running syntax validation..."

# Validate YAML files
if command -v yamllint >/dev/null 2>&1; then
    echo "🔍 Running YAML lint..."
    if yamllint .github/workflows/*.yml k8s-manifests/*.yaml 2>/dev/null; then
        echo "✅ YAML files are valid"
    else
        echo "⚠️  Warning: Some YAML syntax issues found"
    fi
else
    echo "⚠️  yamllint not available, skipping YAML validation"
fi

# Check Python syntax
echo "🔍 Checking Python syntax..."
if python -m py_compile app.py; then
    echo "✅ app.py syntax is valid"
else
    echo "❌ Python syntax errors in app.py"
    exit 1
fi

# Test import of app module
echo "🔍 Testing app module import..."
if python -c "import sys; sys.path.append('.'); import app" 2>/dev/null; then
    echo "✅ App module imports successfully"
else
    echo "⚠️  Warning: App module import issues (may be due to missing dependencies)"
fi

# Check if tests can run
echo ""
echo "🧪 Validating test setup..."
if command -v pytest >/dev/null 2>&1; then
    echo "✅ pytest is available"
    
    # Run a dry-run of tests
    if python -m pytest tests/ --collect-only >/dev/null 2>&1; then
        echo "✅ Tests can be collected successfully"
    else
        echo "⚠️  Warning: Test collection issues found"
    fi
else
    echo "⚠️  pytest not available, install with: pip install pytest pytest-flask pytest-mock"
fi

# Security checks
echo ""
echo "🔒 Security validation..."

# Check for hardcoded secrets
echo "🔍 Checking for potential hardcoded secrets..."
if grep -r -i "password\|secret\|key" --include="*.py" --include="*.yml" --include="*.yaml" . | grep -v "template\|example\|test" | grep -v "secrets.yaml" | grep -v "# " >/dev/null; then
    echo "⚠️  Warning: Potential hardcoded secrets found. Review manually."
else
    echo "✅ No obvious hardcoded secrets detected"
fi

# Check .gitignore coverage
if grep -q "\.env" .gitignore && grep -q "secrets" .gitignore; then
    echo "✅ .gitignore covers sensitive files"
else
    echo "⚠️  Warning: .gitignore may not cover all sensitive files"
fi

# Final summary
echo ""
echo "📊 Validation Summary"
echo "===================="

# Count checks
total_files=0
required_files=(
    ".github/workflows/ci-cd.yml"
    ".github/workflows/security-scan.yml"
    "Dockerfile"
    "requirements.txt"
    "tests/test_app.py"
    "README.md"
    ".gitignore"
)

echo "Required files:"
for file in "${required_files[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
        ((total_files++))
    else
        echo "❌ $file"
    fi
done

echo ""
echo "✅ Validation completed!"
echo "📁 Found $total_files/${#required_files[@]} required files"

if [ $total_files -eq ${#required_files[@]} ]; then
    echo "🎉 All required files are present!"
    echo ""
    echo "🚀 Next Steps:"
    echo "1. Push code to GitHub repository"
    echo "2. Configure GitHub secrets (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, etc.)"
    echo "3. Create ECR repository in AWS"
    echo "4. Set up EKS cluster (if not already done)"
    echo "5. Push to main branch to trigger the CI/CD pipeline"
    echo ""
    echo "📚 See README.md for detailed setup instructions"
else
    echo "⚠️  Some required files are missing. Please review the setup."
    exit 1
fi