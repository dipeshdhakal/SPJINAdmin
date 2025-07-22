#!/bin/bash

echo "🔍 Pre-Deployment Checklist for Oracle Cloud"
echo "============================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check functions
check_pass() {
    echo -e "✅ ${GREEN}$1${NC}"
}

check_fail() {
    echo -e "❌ ${RED}$1${NC}"
}

check_warn() {
    echo -e "⚠️  ${YELLOW}$1${NC}"
}

# Track overall status
ISSUES=0

echo ""
echo "📋 Checking local environment..."

# Check if we're in the right directory
if [ -f "Package.swift" ]; then
    check_pass "In SPJIN project directory"
else
    check_fail "Not in SPJIN project directory"
    ISSUES=$((ISSUES + 1))
fi

# Check if deployment files exist
if [ -f "deploy/oracle-cloud-setup.sh" ]; then
    check_pass "Oracle Cloud setup script found"
else
    check_fail "Oracle Cloud setup script missing"
    ISSUES=$((ISSUES + 1))
fi

if [ -f "deploy/deploy.sh" ]; then
    check_pass "Deployment script found"
else
    check_fail "Deployment script missing"
    ISSUES=$((ISSUES + 1))
fi

if [ -f "deploy/docker-compose.yml" ]; then
    check_pass "Docker Compose configuration found"
else
    check_fail "Docker Compose configuration missing"
    ISSUES=$((ISSUES + 1))
fi

if [ -f "Dockerfile" ]; then
    check_pass "Dockerfile found"
else
    check_fail "Dockerfile missing"
    ISSUES=$((ISSUES + 1))
fi

# Check SSH key
if [ -f "$HOME/.ssh/oracle_cloud_key" ]; then
    check_pass "SSH private key found"
else
    check_warn "SSH key not found at ~/.ssh/oracle_cloud_key"
    echo "   Run: ssh-keygen -t rsa -b 4096 -f ~/.ssh/oracle_cloud_key"
fi

if [ -f "$HOME/.ssh/oracle_cloud_key.pub" ]; then
    check_pass "SSH public key found"
    echo "   📄 Your public key:"
    echo "   $(cat ~/.ssh/oracle_cloud_key.pub)"
else
    check_warn "SSH public key not found"
fi

# Check Docker (local test)
if command -v docker &> /dev/null; then
    check_pass "Docker is available locally (for testing)"
else
    check_warn "Docker not installed locally (not required, but useful for testing)"
fi

# Check Git status
if [ -d ".git" ]; then
    check_pass "Git repository detected"
    
    # Check if there are uncommitted changes
    if [ -n "$(git status --porcelain)" ]; then
        check_warn "You have uncommitted changes"
        echo "   Consider committing and pushing before deployment"
    else
        check_pass "No uncommitted changes"
    fi
    
    # Check remote URL
    REMOTE_URL=$(git remote get-url origin 2>/dev/null)
    if [ -n "$REMOTE_URL" ]; then
        check_pass "Git remote configured: $REMOTE_URL"
    else
        check_warn "No git remote configured"
    fi
else
    check_warn "Not a git repository"
fi

echo ""
echo "🔧 Configuration checks..."

# Check if configure.swift has the updated database path logic
if grep -q "Environment.get(\"DATABASE_PATH\")" Sources/App/configure.swift; then
    check_pass "Database path configuration updated"
else
    check_fail "Database path configuration needs updating"
    ISSUES=$((ISSUES + 1))
fi

# Check if health endpoint exists
if grep -q "/health" Sources/App/routes.swift; then
    check_pass "Health check endpoint configured"
else
    check_warn "Health check endpoint not found"
fi

echo ""
echo "📝 Pre-deployment notes..."

echo ""
echo "🎯 What you'll need for Oracle Cloud:"
echo "   1. Oracle Cloud account (sign up at cloud.oracle.com)"
echo "   2. Your SSH public key (shown above)"
echo "   3. A domain name (optional, can use IP address)"
echo "   4. About 10-15 minutes for deployment"

echo ""
echo "🚀 Next steps:"
echo "   1. Create Oracle Cloud account if you haven't"
echo "   2. Create a VM instance (follow ORACLE_CLOUD_COMPLETE_GUIDE.md)"
echo "   3. Run: ssh -i ~/.ssh/oracle_cloud_key ubuntu@YOUR_VM_IP"
echo "   4. Run the deployment commands from the guide"

echo ""
if [ $ISSUES -eq 0 ]; then
    check_pass "All critical checks passed! Ready for deployment 🎉"
    echo ""
    echo "📖 Next: Follow ORACLE_CLOUD_COMPLETE_GUIDE.md"
else
    check_fail "$ISSUES critical issues found. Please fix before deployment."
    exit 1
fi
