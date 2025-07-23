#!/bin/bash

echo "🧹 Complete Oracle Cloud Cleanup & Fresh Start"
echo "=============================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}⚠️  This will remove ALL Docker containers, images, and free up memory${NC}"
echo -e "${YELLOW}   Make sure you've backed up any important data!${NC}"
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cleanup cancelled"
    exit 1
fi

echo ""
echo "📊 Current system resources BEFORE cleanup:"
echo "Memory:"
free -h
echo ""
echo "Disk:"
df -h /
echo ""
echo "Docker usage:"
docker system df 2>/dev/null || echo "Docker not running"

echo ""
echo -e "${RED}🛑 STEP 1: Stopping all containers and services${NC}"
# Stop SPJIN service
sudo systemctl stop spjin 2>/dev/null || true
sudo systemctl disable spjin 2>/dev/null || true

# Stop all Docker containers
docker-compose down 2>/dev/null || true
docker stop $(docker ps -aq) 2>/dev/null || true
docker kill $(docker ps -aq) 2>/dev/null || true

echo "✅ All containers stopped"

echo ""
echo -e "${RED}🗑️  STEP 2: Removing all Docker resources${NC}"
# Remove all containers
docker rm -f $(docker ps -aq) 2>/dev/null || true

# Remove all images (including base images)
docker rmi -f $(docker images -aq) 2>/dev/null || true

# Remove all volumes
docker volume rm $(docker volume ls -q) 2>/dev/null || true

# Remove all networks (except defaults)
docker network rm $(docker network ls -q --filter type=custom) 2>/dev/null || true

# Remove all build cache
docker builder prune -af 2>/dev/null || true

# Complete system cleanup
docker system prune -af --volumes 2>/dev/null || true

echo "✅ All Docker resources removed"

echo ""
echo -e "${RED}🧽 STEP 3: Cleaning system cache and temporary files${NC}"
# Clear system caches
sudo sync
sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches' 2>/dev/null || true

# Clean apt cache
sudo apt-get clean 2>/dev/null || true
sudo apt-get autoclean 2>/dev/null || true

# Clean temporary files
sudo rm -rf /tmp/* 2>/dev/null || true
sudo rm -rf /var/tmp/* 2>/dev/null || true

# Clean log files
sudo journalctl --vacuum-time=1d 2>/dev/null || true

echo "✅ System cache cleared"

echo ""
echo -e "${RED}💾 STEP 4: Removing swap file (if exists)${NC}"
# Disable and remove swap
sudo swapoff /swapfile 2>/dev/null || true
sudo rm -f /swapfile 2>/dev/null || true

echo "✅ Swap removed"

echo ""
echo -e "${RED}📁 STEP 5: Cleaning application directory${NC}"
# Clean application directory
cd /opt/spjin 2>/dev/null || true
sudo rm -rf * .* 2>/dev/null || true

echo "✅ Application directory cleaned"

echo ""
echo -e "${RED}🔧 STEP 6: Resetting systemd services${NC}"
# Remove systemd service
sudo rm -f /etc/systemd/system/spjin.service 2>/dev/null || true
sudo systemctl daemon-reload

echo "✅ Services reset"

echo ""
echo "📊 System resources AFTER cleanup:"
echo "Memory:"
free -h
echo ""
echo "Disk:"
df -h /
echo ""
echo "Docker status:"
docker system df 2>/dev/null || echo "Docker clean"

echo ""
echo -e "${GREEN}🎉 Complete cleanup finished!${NC}"
echo ""
echo "📋 What was cleaned:"
echo "  ✅ All Docker containers, images, volumes, networks"
echo "  ✅ All build cache and temporary files"
echo "  ✅ System memory cache"
echo "  ✅ Swap file"
echo "  ✅ Application files"
echo "  ✅ Systemd services"
echo ""
echo -e "${GREEN}🚀 Ready for fresh deployment!${NC}"
echo ""
echo "Next steps:"
echo "1. git clone https://github.com/dipeshdhakal/SPJINAdmin.git ."
echo "2. chmod +x deploy/*.sh"
echo "3. ./deploy/deploy.sh YOUR_DOMAIN_OR_IP"
