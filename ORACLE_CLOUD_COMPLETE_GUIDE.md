# Complete Oracle Cloud Setup & Deployment Guide for SPJIN

This is a comprehensive guide for beginners to deploy your SPJIN Vapor app on Oracle Cloud's Always Free tier.

## 🎯 What You'll Get (Always Free)
- **2 AMD-based VMs** (1/8 OCPU, 1GB RAM each) OR
- **Up to 4 Arm-based Ampere A1 cores** and 24GB RAM (Better option!)
- **200GB Block Volume storage**
- **10GB Object Storage**
- **Always Free** - No time limits, no credit card charges

---

## 📋 Prerequisites

Before starting, make sure you have:
- [ ] A valid email address
- [ ] Phone number for verification
- [ ] SSH key pair (we'll create this if you don't have one)
- [ ] Your SPJIN project code (this repository)

---

## Part 1: Oracle Cloud Account Setup

### Step 1: Create Oracle Cloud Account

1. **Visit Oracle Cloud**
   - Go to [cloud.oracle.com](https://cloud.oracle.com)
   - Click **"Start for free"**

2. **Fill Registration Form**
   - **Country/Territory**: Select your country
   - **Name**: Your full name
   - **Email**: Use a valid email (you'll need to verify it)
   - **Password**: Create a strong password
   - **Company**: You can put your name or "Personal"

3. **Verify Phone Number**
   - Enter your phone number
   - Enter the verification code sent via SMS

4. **Verify Email**
   - Check your email for verification link
   - Click the verification link

5. **Add Payment Method** (Required but Won't Be Charged)
   - Add a credit card (for identity verification only)
   - ⚠️ **Important**: Always Free resources never charge your card
   - Oracle needs this to prevent abuse

6. **Wait for Account Activation**
   - This can take a few minutes to a few hours
   - You'll receive an email when your account is ready

---

## Part 2: Oracle Cloud Console Setup

### Step 2: Access Oracle Cloud Console

1. **Sign In**
   - Go to [cloud.oracle.com](https://cloud.oracle.com)
   - Click **"Sign In"**
   - Enter your email and password

2. **Select Your Tenancy**
   - If prompted, select your cloud account (tenancy)
   - You'll be taken to the Oracle Cloud Console dashboard

### Step 3: Create SSH Key Pair (If You Don't Have One)

**On macOS/Linux:**
```bash
# Create .ssh directory if it doesn't exist
mkdir -p ~/.ssh

# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -f ~/.ssh/oracle_cloud_key

# When prompted:
# - Press Enter for default location
# - Enter a passphrase (optional but recommended)
# - Confirm passphrase

# View your public key (you'll need this later)
cat ~/.ssh/oracle_cloud_key.pub
```

**Copy the entire public key output** - you'll need it when creating the VM.

---

## Part 3: Create Virtual Machine

### Step 4: Create Compute Instance

1. **Navigate to Compute**
   - In Oracle Cloud Console, click the **hamburger menu** (☰) in top-left
   - Go to **"Compute"** → **"Instances"**

2. **Create Instance**
   - Click **"Create Instance"** button
   - You'll see the "Create Compute Instance" form

3. **Basic Information**
   - **Name**: `spjin-vapor-app` (or any name you prefer)
   - **Compartment**: Leave as "root" (default)

4. **Image and Shape**
   
   **Image Selection:**
   - Click **"Edit"** next to "Image and shape"
   - Click **"Change Image"**
   - Select **"Canonical Ubuntu"**
   - Choose **"Ubuntu 22.04"** (recommended)
   - Click **"Select Image"**

   **Shape Selection:**
   - Click **"Change Shape"**
   - Select **"Ampere"** (recommended for better performance)
   - Choose **"VM.Standard.A1.Flex"**
   - Set **OCPUs: 2** and **Memory: 12 GB** (this uses half your free allowance)
   - OR select **"AMD"** and choose **"VM.Standard.E2.1.Micro"** (1GB RAM)
   - Click **"Select Shape"**

5. **Networking**
   - **Virtual Cloud Network**: Leave default (it will create one)
   - **Subnet**: Leave default (public subnet)
   - **Public IP**: Make sure **"Assign a public IPv4 address"** is checked ✅

6. **SSH Keys**
   - Select **"Paste public keys"**
   - Paste your SSH public key (from Step 3)
   - Make sure the entire key is pasted correctly

7. **Boot Volume**
   - Leave default settings (50GB is fine)

8. **Create Instance**
   - Click **"Create"** button
   - The instance will start provisioning (takes 1-3 minutes)

### Step 5: Note Your Instance Details

Once the instance is running:
1. **Public IP Address**: Copy this (you'll need it to connect)
2. **Username**: `ubuntu` (for Ubuntu instances)
3. **Instance OCID**: Copy this for reference

---

## Part 4: Configure Network Security

### Step 6: Configure Security Lists

1. **Navigate to Networking**
   - Go to **"Networking"** → **"Virtual Cloud Networks"**
   - Click on your VCN (usually named like "vcn-...")

2. **Access Security Lists**
   - Click **"Security Lists"** in the left menu
   - Click on **"Default Security List for vcn-..."**

3. **Add Ingress Rules**
   
   **Rule 1: HTTP (Port 80)**
   - Click **"Add Ingress Rules"**
   - **Source Type**: CIDR
   - **Source CIDR**: `0.0.0.0/0`
   - **IP Protocol**: TCP
   - **Destination Port Range**: `80`
   - **Description**: `HTTP traffic`
   - Click **"Add Ingress Rules"**

   **Rule 2: HTTPS (Port 443)**
   - Click **"Add Ingress Rules"**
   - **Source Type**: CIDR
   - **Source CIDR**: `0.0.0.0/0`
   - **IP Protocol**: TCP
   - **Destination Port Range**: `443`
   - **Description**: `HTTPS traffic`
   - Click **"Add Ingress Rules"**

   **Note**: SSH (port 22) should already be open by default.

---

## Part 5: Connect to Your Server

### Step 7: SSH to Your Instance

```bash
# Connect to your server
ssh -i ~/.ssh/oracle_cloud_key ubuntu@YOUR_PUBLIC_IP

# Replace YOUR_PUBLIC_IP with the actual IP address from Step 5
# Example: ssh -i ~/.ssh/oracle_cloud_key ubuntu@150.230.45.123
```

**First-time connection:**
- You'll see a message about host authenticity
- Type `yes` and press Enter
- You should now be connected to your Ubuntu server!

---

## Part 6: Server Setup and Deployment

### Step 8: Download and Run Setup Script

Once connected to your server:

```bash
# Download the setup script
wget https://raw.githubusercontent.com/dipeshdhakal/SPJINAdmin/main/deploy/oracle-cloud-setup.sh

# Make it executable
chmod +x oracle-cloud-setup.sh

# Run the setup script
./oracle-cloud-setup.sh
```

This script will:
- Update the system
- Install Docker and Docker Compose
- Install Nginx for reverse proxy
- Configure firewall
- Set up SSL certificate tools
- Create application directories

**Important**: After the script completes, you MUST log out and log back in:
```bash
# Log out
exit

# Log back in (this applies Docker group membership)
ssh -i ~/.ssh/oracle_cloud_key ubuntu@YOUR_PUBLIC_IP
```

### Step 9: Deploy Your Application

```bash
# Navigate to the application directory and clean it
cd /opt/spjin
sudo rm -rf * .*  2>/dev/null || true

# Clone your repository
git clone https://github.com/dipeshdhakal/SPJINAdmin.git .

# Make deployment scripts executable
chmod +x deploy/deploy.sh deploy/oc-commands.sh

# Run the deployment
./deploy/deploy.sh YOUR_DOMAIN_OR_IP

# Examples:
# If you have a domain: ./deploy/deploy.sh myapp.example.com
# If using IP only: ./deploy/deploy.sh 150.230.45.123
```

The deployment script will:
- Create secure environment variables
- Build your Docker containers
- Start the application
- Configure Nginx reverse proxy
- Set up SSL certificates (if you provided a domain)

---

## Part 7: Verify Deployment

### Step 10: Test Your Application

1. **Check Application Status**
   ```bash
   ./deploy/oc-commands.sh status
   ```

2. **View Application Logs**
   ```bash
   ./deploy/oc-commands.sh logs
   ```

3. **Test Health Endpoint**
   ```bash
   curl http://localhost:8080/health
   ```

4. **Access via Web Browser**
   - Open your browser
   - Go to `http://YOUR_PUBLIC_IP` or `http://your-domain.com`
   - You should see your SPJIN application!

---

## Part 8: Domain Setup (Optional)

### Step 11: Configure Custom Domain

If you have a domain name:

1. **Update DNS Records**
   - Go to your domain registrar (GoDaddy, Namecheap, etc.)
   - Add an **A record** pointing to your Oracle Cloud public IP
   - Example: `myapp.example.com` → `150.230.45.123`

2. **Setup SSL Certificate**
   ```bash
   ./deploy/oc-commands.sh ssl your-domain.com
   ```

3. **Update Nginx Configuration**
   - The deployment script will automatically configure SSL
   - Your site will be available at `https://your-domain.com`

---

## Part 9: Application Management

### Step 12: Common Management Tasks

```bash
# Check application status
./deploy/oc-commands.sh status

# View logs
./deploy/oc-commands.sh logs

# Restart application
./deploy/oc-commands.sh restart

# Update from git
./deploy/oc-commands.sh update

# Create database backup
./deploy/oc-commands.sh backup

# Monitor system resources
./deploy/oc-commands.sh monitor

# Clean up Docker resources
./deploy/oc-commands.sh clean
```

### Step 13: Database Management

```bash
# Create backup
./deploy/oc-commands.sh backup

# List backups
ls -la /opt/spjin/backups/

# Restore from backup
./deploy/oc-commands.sh restore db_backup_YYYYMMDD_HHMMSS.sqlite
```

---

## 🚨 Troubleshooting

### Common Issues and Solutions

**1. Git clone fails: "destination path '.' already exists and is not an empty directory"**
```bash
# Clean the directory first
cd /opt/spjin
sudo rm -rf * .*  2>/dev/null || true

# Then clone
git clone https://github.com/dipeshdhakal/SPJINAdmin.git .
```

**2. Can't connect via SSH**
```bash
# Check if you're using the correct key and IP
ssh -i ~/.ssh/oracle_cloud_key ubuntu@YOUR_IP -v

# Make sure security groups allow SSH (port 22)
```

**3. Application won't start**
```bash
# Check logs
docker-compose logs spjin-app

# Restart services
sudo systemctl restart docker
docker-compose restart
```

**4. Can't access website**
```bash
# Check if ports 80/443 are open in security lists
# Check if application is running
curl http://localhost:8080/health

# Check nginx status
docker-compose logs nginx
```

**4. Out of disk space**
```bash
# Check disk usage
df -h

# Clean up Docker
docker system prune -f
```

**5. SSL certificate issues**
```bash
# Check certificate status
sudo certbot certificates

# Renew manually
sudo certbot renew
docker-compose restart nginx
```

---

## 💡 Performance Tips

1. **Use Ampere A1 instances** - Better performance than AMD for the same free tier
2. **Monitor resources** - Use `./deploy/oc-commands.sh monitor`
3. **Regular backups** - Set up automated backups
4. **Keep system updated** - Run `sudo apt update && sudo apt upgrade` monthly

---

## 🎉 Congratulations!

Your SPJIN Vapor application is now running on Oracle Cloud! 

**What you have:**
- ✅ Production-ready Vapor app
- ✅ SQLite database with persistence
- ✅ Nginx reverse proxy
- ✅ SSL certificates (if domain configured)
- ✅ Automated backups
- ✅ Health monitoring
- ✅ Zero ongoing costs (Always Free tier)

**Next steps:**
1. Access your admin panel at your domain/IP
2. Import your data
3. Configure regular backups
4. Monitor application performance

Your app is ready for production use! 🚀
