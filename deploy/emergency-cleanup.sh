#!/bin/bash

# Quick cleanup - one command to rule them all
echo "🚨 EMERGENCY CLEANUP - Removing everything..."

# Stop everything
sudo systemctl stop spjin 2>/dev/null || true
docker-compose down 2>/dev/null || true
docker stop $(docker ps -aq) 2>/dev/null || true

# Remove all Docker resources
docker system prune -af --volumes 2>/dev/null || true
docker rmi -f $(docker images -aq) 2>/dev/null || true

# Clear caches
sudo sync && sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches' 2>/dev/null || true

# Remove swap
sudo swapoff /swapfile 2>/dev/null || true
sudo rm -f /swapfile 2>/dev/null || true

# Clean app directory
cd /opt/spjin && sudo rm -rf * .* 2>/dev/null || true

echo "✅ Emergency cleanup complete! Memory freed."
echo "📊 Current memory:"
free -h
