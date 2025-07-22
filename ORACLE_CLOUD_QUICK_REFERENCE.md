# Oracle Cloud Quick Reference

## 🔗 Essential Information
**Save these details after setup:**
- **Public IP**: `___________________`
- **SSH Command**: `ssh -i ~/.ssh/oracle_cloud_key ubuntu@YOUR_IP`
- **App URL**: `http://YOUR_IP` or `https://your-domain.com`
- **Admin Panel**: `http://YOUR_IP/admin`

## ⚡ Quick Commands

### SSH Connection
```bash
ssh -i ~/.ssh/oracle_cloud_key ubuntu@YOUR_PUBLIC_IP
```

### Application Management
```bash
cd /opt/spjin

# Check status
./deploy/oc-commands.sh status

# View logs
./deploy/oc-commands.sh logs

# Restart app
./deploy/oc-commands.sh restart

# Update code
./deploy/oc-commands.sh update

# Create backup
./deploy/oc-commands.sh backup

# Monitor resources
./deploy/oc-commands.sh monitor
```

### Docker Commands
```bash
# View running containers
docker-compose ps

# View logs
docker-compose logs -f spjin-app

# Restart containers
docker-compose restart

# Rebuild and restart
docker-compose build --no-cache && docker-compose up -d
```

### System Commands
```bash
# Check disk space
df -h

# Check memory usage
free -h

# Check system load
top

# Update system
sudo apt update && sudo apt upgrade
```

## 🚨 Emergency Commands

### If app is down
```bash
cd /opt/spjin
docker-compose restart
sudo systemctl restart spjin
```

### If server is unresponsive
```bash
# Reboot server (from Oracle Cloud Console)
# Or SSH and run:
sudo reboot
```

### Database recovery
```bash
# List backups
ls -la /opt/spjin/backups/

# Restore from backup
./deploy/oc-commands.sh restore BACKUP_FILENAME
```

## 📞 Support Resources
- **Oracle Cloud Docs**: [docs.oracle.com](https://docs.oracle.com/iaas/)
- **Oracle Cloud Support**: [cloud.oracle.com/support](https://cloud.oracle.com/support)
- **Community Forums**: [community.oracle.com](https://community.oracle.com)

## 💾 Backup Strategy
```bash
# Manual backup
./deploy/oc-commands.sh backup

# View backups
ls -la /opt/spjin/backups/

# Automated daily backups are already configured
```

## 🔒 Security Checklist
- [ ] SSH key authentication only
- [ ] Firewall configured (ports 22, 80, 443)
- [ ] SSL certificate installed
- [ ] Regular system updates
- [ ] Database backups working
- [ ] Non-root user (vapor)
- [ ] Secure JWT secret configured
