# 🚨 NUCLEAR OPTION: Complete Fresh Start

## When to Use This
- Build is completely stuck
- Out of memory/disk space  
- Want to start completely fresh
- Everything is broken

## ⚠️ WARNING
This will delete EVERYTHING:
- All Docker containers and images
- All application data
- Swap files
- Build cache
- System cache

**Only use if you have backups or don't mind losing data!**

---

## 🧹 Method 1: Automated Complete Cleanup

```bash
# SSH to your Oracle Cloud server
ssh -i ~/.ssh/oracle_cloud_key ubuntu@YOUR_PUBLIC_IP

# Go to app directory
cd /opt/spjin

# Run complete cleanup (if files exist)
chmod +x deploy/complete-cleanup.sh
./deploy/complete-cleanup.sh

# Start fresh deployment
git clone https://github.com/dipeshdhakal/SPJINAdmin.git .
chmod +x deploy/*.sh verify-deployment-files.sh
./deploy/deploy.sh YOUR_DOMAIN_OR_IP
```

---

## 🚨 Method 2: Emergency One-Liner

```bash
# If you're in a hurry, run this single command:
cd /opt/spjin && chmod +x deploy/emergency-cleanup.sh && ./deploy/emergency-cleanup.sh

# Then redeploy:
git clone https://github.com/dipeshdhakal/SPJINAdmin.git .
chmod +x deploy/*.sh
./deploy/deploy.sh YOUR_DOMAIN_OR_IP
```

---

## 🔧 Method 3: Manual Nuclear Cleanup

```bash
# Stop everything
sudo systemctl stop spjin
docker-compose down
docker stop $(docker ps -aq)
docker kill $(docker ps -aq)

# Remove ALL Docker resources
docker rm -f $(docker ps -aq)
docker rmi -f $(docker images -aq)
docker volume rm $(docker volume ls -q)
docker system prune -af --volumes

# Clear system memory
sudo sync
sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'

# Remove swap
sudo swapoff /swapfile
sudo rm -f /swapfile

# Clean app directory
cd /opt/spjin
sudo rm -rf * .*

# Clean system files
sudo apt-get clean
sudo rm -rf /tmp/*
sudo journalctl --vacuum-time=1d

# Remove service
sudo rm -f /etc/systemd/system/spjin.service
sudo systemctl daemon-reload

# Check memory is freed
free -h
df -h
```

---

## 🚀 After Cleanup: Fresh Deployment

```bash
# Clone repository
cd /opt/spjin
git clone https://github.com/dipeshdhakal/SPJINAdmin.git .

# Make scripts executable
chmod +x deploy/*.sh verify-deployment-files.sh

# Optional: Verify files
./verify-deployment-files.sh

# Deploy with optimizations
./deploy/deploy.sh YOUR_DOMAIN_OR_IP
```

---

## 📊 Verify Cleanup Success

```bash
# Check memory (should be mostly free)
free -h

# Check disk space (should have more available)
df -h

# Check Docker is clean
docker system df

# Check no containers running
docker ps -a

# Check no images
docker images
```

---

## 💡 Tips for Success After Cleanup

1. **Add swap first**: Create swap before building
2. **Use optimized build**: Let the scripts use low-memory settings
3. **Be patient**: Initial build takes 15-30 minutes
4. **Monitor progress**: Use `docker-compose logs -f` to watch
5. **Don't interrupt**: Let the build complete fully

---

## 🎯 Expected Results

After complete cleanup:
- **Memory usage**: < 200MB used
- **Disk space**: 5-10GB free
- **Docker**: No containers or images
- **Fresh start**: Like a new server

Your Oracle Cloud instance will be like new! 🎉
