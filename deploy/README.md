# Oracle Cloud Free Tier Deployment Guide for SPJIN

This guide will help you deploy your SPJIN Vapor application to Oracle Cloud's Always Free tier.

## 🎯 Oracle Cloud Always Free Benefits
- **2 AMD-based Compute VMs** (1/8 OCPU, 1 GB RAM each)
- **Up to 4 Arm-based Ampere A1 cores** and 24 GB RAM
- **200 GB Block Volume storage**
- **Always Free** - no time limits!

## 📋 Prerequisites

1. Oracle Cloud account (sign up at cloud.oracle.com)
2. Domain name (optional, can use IP address initially)
3. SSH key pair for server access

## 🚀 Step-by-Step Deployment

### Step 1: Create Oracle Cloud VM

1. **Sign in to Oracle Cloud Console**
   - Go to cloud.oracle.com and sign in

2. **Create Compute Instance**
   - Navigate to Compute → Instances
   - Click "Create Instance"
   - Name: `spjin-vapor-app`
   - Image: Ubuntu 22.04 (recommended)
   - Shape: VM.Standard.E2.1.Micro (Always Free)
   - Add your SSH public key
   - Note down the public IP address

3. **Configure Network Security**
   - Go to Networking → Virtual Cloud Networks
   - Select your VCN → Security Lists → Default Security List
   - Add Ingress Rules:
     - Port 80 (HTTP): Source CIDR 0.0.0.0/0
     - Port 443 (HTTPS): Source CIDR 0.0.0.0/0
     - Port 22 (SSH): Source CIDR 0.0.0.0/0

### Step 2: Connect and Setup Server

1. **SSH to your server**
   ```bash
   ssh -i your-key.pem ubuntu@YOUR_VM_IP
   ```

2. **Run the setup script**
   ```bash
   # Download and run setup script
   wget https://raw.githubusercontent.com/your-username/SPJINAdmin/main/deploy/oracle-cloud-setup.sh
   chmod +x oracle-cloud-setup.sh
   ./oracle-cloud-setup.sh
   
   # Log out and back in to apply Docker group changes
   exit
   ssh -i your-key.pem ubuntu@YOUR_VM_IP
   ```

### Step 3: Deploy Application

1. **Clone your repository**
   ```bash
   cd /opt/spjin
   git clone https://github.com/your-username/SPJINAdmin.git .
   ```

2. **Run deployment script**
   ```bash
   chmod +x deploy/deploy.sh
   ./deploy/deploy.sh your-domain.com
   # Or use IP address if no domain: ./deploy/deploy.sh
   ```

### Step 4: Access Your Application

1. **Test the deployment**
   ```bash
   curl http://localhost:8080/health
   ```

2. **Access via web browser**
   - HTTP: `http://YOUR_VM_IP` or `http://your-domain.com`
   - HTTPS: `https://your-domain.com` (if SSL configured)

## 🔧 Management Commands

```bash
# View application logs
docker-compose logs -f

# Restart application
sudo systemctl restart spjin

# Stop application
sudo systemctl stop spjin

# Update application
cd /opt/spjin
git pull
docker-compose build --no-cache
docker-compose up -d

# Backup database
cp /opt/spjin/data/db.sqlite /opt/spjin/backup-$(date +%Y%m%d).sqlite

# View system resources
htop
df -h
docker stats
```

## 🔐 Security Best Practices

1. **Change default passwords** - Update admin credentials after first login
2. **Regular backups** - Backup your SQLite database regularly
3. **Keep system updated** - Run `sudo apt update && sudo apt upgrade` regularly
4. **Monitor logs** - Check application and system logs regularly
5. **SSL certificates** - Use Let's Encrypt for free SSL certificates

## 🚨 Troubleshooting

### Application won't start
```bash
# Check logs
docker-compose logs spjin-app

# Check if ports are bound
sudo netstat -tulpn | grep :8080

# Restart Docker
sudo systemctl restart docker
docker-compose up -d
```

### Database issues
```bash
# Check database file permissions
ls -la /opt/spjin/data/

# Recreate database (WARNING: This will delete all data)
rm /opt/spjin/data/db.sqlite
docker-compose restart spjin-app
```

### SSL certificate issues
```bash
# Check certificate status
sudo certbot certificates

# Renew certificate manually
sudo certbot renew
docker-compose restart nginx
```

### Out of memory
```bash
# Check memory usage
free -h
docker stats

# Restart services to free memory
docker-compose restart
```

## 📊 Resource Monitoring

```bash
# Check disk usage
df -h

# Check memory usage
free -h

# Check CPU usage
top

# Check Docker containers
docker ps
docker stats
```

## 🔄 Backup Strategy

```bash
# Create backup script
cat > /opt/spjin/backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/opt/spjin/backups"
DATE=$(date +%Y%m%d_%H%M%S)

mkdir -p $BACKUP_DIR

# Backup database
cp /opt/spjin/data/db.sqlite $BACKUP_DIR/db_backup_$DATE.sqlite

# Backup environment
cp /opt/spjin/.env $BACKUP_DIR/env_backup_$DATE

# Keep only last 7 days of backups
find $BACKUP_DIR -name "*.sqlite" -mtime +7 -delete
find $BACKUP_DIR -name "env_backup_*" -mtime +7 -delete

echo "Backup completed: $DATE"
EOF

chmod +x /opt/spjin/backup.sh

# Add to crontab for daily backups
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/spjin/backup.sh") | crontab -
```

## 💡 Performance Tips

1. **Use Ampere A1 instances** - Better performance for the same free tier
2. **Enable swap** - Add swap space for better memory management
3. **Use nginx caching** - Cache static assets
4. **Monitor resources** - Use `htop` and `docker stats` regularly
5. **Optimize database** - Regular VACUUM operations for SQLite

## 🎯 Next Steps

1. Point your domain to the server IP
2. Configure SSL certificate with Let's Encrypt
3. Set up regular database backups
4. Monitor application performance
5. Configure log rotation
6. Set up monitoring and alerting

Your SPJIN Vapor application is now running on Oracle Cloud's Always Free tier! 🎉
