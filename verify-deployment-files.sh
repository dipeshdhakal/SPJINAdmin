#!/bin/bash

echo "🔍 Pre-Deployment File Verification"
echo "==================================="

# Track issues
ISSUES=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_pass() {
    echo -e "✅ ${GREEN}$1${NC}"
}

check_fail() {
    echo -e "❌ ${RED}$1${NC}"
    ISSUES=$((ISSUES + 1))
}

check_warn() {
    echo -e "⚠️  ${YELLOW}$1${NC}"
}

echo "📋 Checking required deployment files..."

# Check main project files
if [ -f "Package.swift" ]; then
    check_pass "Package.swift found"
else
    check_fail "Package.swift missing - not in SPJIN project directory?"
fi

if [ -f "Dockerfile" ]; then
    check_pass "Dockerfile found"
else
    check_fail "Dockerfile missing"
fi

# Check deployment files
if [ -f "deploy/deploy.sh" ]; then
    check_pass "deploy/deploy.sh found"
else
    check_fail "deploy/deploy.sh missing"
fi

if [ -f "deploy/docker-compose.yml" ]; then
    check_pass "deploy/docker-compose.yml found"
else
    check_fail "deploy/docker-compose.yml missing"
fi

if [ -f "deploy/nginx/nginx.conf" ]; then
    check_pass "deploy/nginx/nginx.conf found"
else
    check_fail "deploy/nginx/nginx.conf missing"
fi

if [ -f "deploy/oc-commands.sh" ]; then
    check_pass "deploy/oc-commands.sh found"
else
    check_fail "deploy/oc-commands.sh missing"
fi

# Check if scripts are executable
if [ -x "deploy/deploy.sh" ]; then
    check_pass "deploy/deploy.sh is executable"
else
    check_warn "deploy/deploy.sh is not executable - run: chmod +x deploy/deploy.sh"
fi

if [ -x "deploy/oc-commands.sh" ]; then
    check_pass "deploy/oc-commands.sh is executable"
else
    check_warn "deploy/oc-commands.sh is not executable - run: chmod +x deploy/oc-commands.sh"
fi

echo ""
echo "📂 Checking directory structure..."

if [ -d "Sources/App" ]; then
    check_pass "Sources/App directory found"
else
    check_fail "Sources/App directory missing"
fi

if [ -d "Resources/Views" ]; then
    check_pass "Resources/Views directory found"
else
    check_fail "Resources/Views directory missing"
fi

echo ""
if [ $ISSUES -eq 0 ]; then
    check_pass "All required files are present! 🎉"
    echo ""
    echo "✅ Ready for deployment!"
    echo "Next steps:"
    echo "1. SSH to your Oracle Cloud server"
    echo "2. Run: cd /opt/spjin && ./deploy/deploy.sh YOUR_DOMAIN_OR_IP"
    exit 0
else
    check_fail "$ISSUES file(s) missing or incorrect"
    echo ""
    echo "❌ Fix the issues above before deploying"
    echo ""
    echo "💡 If files are missing, you may need to:"
    echo "1. Make sure you're in the SPJIN project directory"
    echo "2. Re-clone the repository: git clone https://github.com/dipeshdhakal/SPJINAdmin.git"
    echo "3. Make scripts executable: chmod +x deploy/*.sh"
    exit 1
fi
