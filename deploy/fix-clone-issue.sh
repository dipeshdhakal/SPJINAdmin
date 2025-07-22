#!/bin/bash

echo "🔧 Fixing Git Clone Issue on Oracle Cloud"
echo "========================================"

# Check if we're in the right directory
if [ ! -d "/opt/spjin" ]; then
    echo "❌ /opt/spjin directory not found. Are you on the Oracle Cloud server?"
    exit 1
fi

echo "📁 Cleaning /opt/spjin directory..."
cd /opt/spjin

# Show what's currently in the directory
echo "📋 Current contents:"
ls -la

# Ask for confirmation
echo ""
echo "⚠️  This will delete all files in /opt/spjin and re-clone the repository."
echo "   Continue? (y/N)"
read -r response

if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
    echo "🧹 Cleaning directory..."
    sudo rm -rf * .*  2>/dev/null || true
    
    echo "📥 Cloning repository..."
    git clone https://github.com/dipeshdhakal/SPJINAdmin.git .
    
    if [ $? -eq 0 ]; then
        echo "✅ Repository cloned successfully!"
        
        echo "🔧 Making scripts executable..."
        chmod +x deploy/deploy.sh deploy/oc-commands.sh 2>/dev/null || true
        
        echo ""
        echo "🎉 Ready for deployment!"
        echo "Next step: ./deploy/deploy.sh YOUR_DOMAIN_OR_IP"
    else
        echo "❌ Failed to clone repository. Check your internet connection and try again."
        exit 1
    fi
else
    echo "❌ Operation cancelled."
    exit 1
fi
