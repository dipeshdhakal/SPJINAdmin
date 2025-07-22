# Oracle Cloud Deployment - Step by Step Tutorial

## 🎬 Tutorial Overview
**Total Time**: ~30 minutes  
**Difficulty**: Beginner-friendly  
**Cost**: $0 (Always Free tier)

---

## 🎯 Phase 1: Local Preparation (5 minutes)

### Step 1.1: Check Your Setup
```bash
# Run this in your SPJIN project directory
./pre-deployment-check.sh
```

### Step 1.2: Create SSH Key (if needed)
```bash
# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/oracle_cloud_key

# View your public key (copy this!)
cat ~/.ssh/oracle_cloud_key.pub
```

**✅ Checkpoint**: You should have:
- SSH key pair created
- Public key copied to clipboard
- All project files ready

---

## 🌩️ Phase 2: Oracle Cloud Account Setup (10 minutes)

### Step 2.1: Create Account
1. Go to [cloud.oracle.com](https://cloud.oracle.com)
2. Click **"Start for free"**
3. Fill in your details (name, email, phone)
4. Verify phone number and email
5. Add credit card (for verification only)
6. Wait for account activation (check email)

### Step 2.2: Access Console
1. Sign in to Oracle Cloud Console
2. You'll see the main dashboard
3. Familiarize yourself with the navigation menu (☰)

**✅ Checkpoint**: You should be logged into Oracle Cloud Console

---

## 💻 Phase 3: Create Virtual Machine (10 minutes)

### Step 3.1: Start VM Creation
1. Navigate: **Compute** → **Instances**
2. Click **"Create Instance"**
3. Name it: `spjin-vapor-app`

### Step 3.2: Configure VM
**Image**: 
- Click **"Change Image"**
- Select **"Canonical Ubuntu"**
- Choose **"Ubuntu 22.04"**

**Shape**:
- Click **"Change Shape"**
- Select **"Ampere"** (recommended)
- Choose **"VM.Standard.A1.Flex"**
- Set: **2 OCPUs, 12GB RAM**

**Networking**:
- Keep defaults
- Ensure **"Assign public IP"** is checked ✅

**SSH Keys**:
- Select **"Paste public keys"**
- Paste your SSH public key from Step 1.2

### Step 3.3: Create and Wait
1. Click **"Create"**
2. Wait 2-3 minutes for provisioning
3. **Copy the Public IP address** when ready

**✅ Checkpoint**: VM is running with a public IP

---

## 🔒 Phase 4: Configure Network Security (5 minutes)

### Step 4.1: Open Required Ports
1. Navigate: **Networking** → **Virtual Cloud Networks**
2. Click your VCN name
3. Click **"Security Lists"**
4. Click **"Default Security List..."**

### Step 4.2: Add Rules
**Add Rule 1 (HTTP)**:
- Click **"Add Ingress Rules"**
- Source CIDR: `0.0.0.0/0`
- Protocol: TCP
- Port Range: `80`
- Click **"Add Ingress Rules"**

**Add Rule 2 (HTTPS)**:
- Click **"Add Ingress Rules"**
- Source CIDR: `0.0.0.0/0`
- Protocol: TCP
- Port Range: `443`
- Click **"Add Ingress Rules"**

**✅ Checkpoint**: Ports 22, 80, and 443 are open

---

## 🚀 Phase 5: Deploy Your Application (15 minutes)

### Step 5.1: Connect to Server
```bash
# Connect via SSH (replace YOUR_IP with actual IP)
ssh -i ~/.ssh/oracle_cloud_key ubuntu@YOUR_PUBLIC_IP

# You should now be connected to your Ubuntu server
```

### Step 5.2: Run Setup Script
```bash
# Download and run the setup script
wget https://raw.githubusercontent.com/dipeshdhakal/SPJINAdmin/main/deploy/oracle-cloud-setup.sh
chmod +x oracle-cloud-setup.sh
./oracle-cloud-setup.sh
```

**Important**: Log out and back in after setup:
```bash
exit
ssh -i ~/.ssh/oracle_cloud_key ubuntu@YOUR_PUBLIC_IP
```

### Step 5.3: Deploy Application
```bash
# Go to app directory
cd /opt/spjin

# Clone your code
git clone https://github.com/dipeshdhakal/SPJINAdmin.git .

# Make scripts executable
chmod +x deploy/deploy.sh deploy/oc-commands.sh

# Deploy (replace with your domain or IP)
./deploy/deploy.sh YOUR_DOMAIN_OR_IP
```

### Step 5.4: Verify Deployment
```bash
# Check if everything is running
./deploy/oc-commands.sh status

# Test the health endpoint
curl http://localhost:8080/health

# Should return: {"status":"healthy",...}
```

**✅ Checkpoint**: Application is running and accessible

---

## 🎉 Phase 6: Access Your Application (2 minutes)

### Step 6.1: Open in Browser
1. Open your web browser
2. Go to: `http://YOUR_PUBLIC_IP`
3. You should see your SPJIN application!

### Step 6.2: Access Admin Panel
1. Go to: `http://YOUR_PUBLIC_IP/admin`
2. Use your admin credentials to log in
3. You can now manage your content!

**✅ Final Checkpoint**: Application is live and accessible!

---

## 🔧 Bonus: Management Commands

### Daily Operations
```bash
# SSH to your server
ssh -i ~/.ssh/oracle_cloud_key ubuntu@YOUR_PUBLIC_IP

# Check status
cd /opt/spjin && ./deploy/oc-commands.sh status

# View logs
./deploy/oc-commands.sh logs

# Create backup
./deploy/oc-commands.sh backup

# Monitor resources
./deploy/oc-commands.sh monitor
```

### Updates
```bash
# Update your application
./deploy/oc-commands.sh update

# Restart if needed
./deploy/oc-commands.sh restart
```

---

## 🆘 Troubleshooting Quick Fixes

### Can't connect via SSH?
```bash
# Check your command syntax
ssh -i ~/.ssh/oracle_cloud_key ubuntu@YOUR_IP -v

# Verify security groups allow port 22
```

### Application not loading?
```bash
# Check if containers are running
docker-compose ps

# Restart everything
./deploy/oc-commands.sh restart
```

### Need help?
1. Check the logs: `./deploy/oc-commands.sh logs`
2. Refer to: `ORACLE_CLOUD_COMPLETE_GUIDE.md`
3. Use: `ORACLE_CLOUD_QUICK_REFERENCE.md`

---

## 🎊 Congratulations!

You've successfully deployed your SPJIN Vapor application to Oracle Cloud!

**What you now have:**
- ✅ Production-ready Vapor app
- ✅ Free hosting (always!)
- ✅ SSL-ready (when you add a domain)
- ✅ Automated backups
- ✅ Easy management commands
- ✅ Persistent database storage

**Your app is live at**: `http://YOUR_PUBLIC_IP`

Welcome to the cloud! 🚀☁️
