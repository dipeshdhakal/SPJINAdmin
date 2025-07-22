#!/bin/bash
set -e

echo "🚀 Oracle Cloud VM Setup Script for SPJIN Vapor App"
echo "================================================="

# Update system
echo "📦 Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install essential packages
echo "📦 Installing essential packages..."
sudo apt install -y \
    curl \
    wget \
    git \
    unzip \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    gnupg \
    lsb-release \
    ufw \
    nginx \
    certbot \
    python3-certbot-nginx

# Install Docker
echo "🐳 Installing Docker..."
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose
echo "🐳 Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Configure firewall
echo "🔥 Configuring firewall..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

# Create application directory
echo "📁 Creating application directory..."
sudo mkdir -p /opt/spjin
sudo chown $USER:$USER /opt/spjin

# Create data directory for SQLite
mkdir -p /opt/spjin/data

echo "✅ Oracle Cloud VM setup completed!"
echo ""
echo "Next steps:"
echo "1. Clone your repository to /opt/spjin"
echo "2. Configure environment variables"
echo "3. Run the deployment script"
echo ""
echo "⚠️  Please log out and log back in to apply Docker group changes"
