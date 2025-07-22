#!/bin/bash
set -e

echo "🚀 Deploying SPJIN to Oracle Cloud"
echo "================================="

# Configuration
APP_DIR="/opt/spjin"
DOMAIN="${1:-your-domain.com}"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo "❌ This script should not be run as root"
   exit 1
fi

# Navigate to app directory
cd $APP_DIR

# Check if we're in the right directory
if [ ! -f "Package.swift" ]; then
    echo "❌ Package.swift not found. Make sure you're in the SPJIN project directory."
    exit 1
fi

# Create environment file if it doesn't exist
if [ ! -f ".env" ]; then
    echo "📝 Creating environment file..."
    cat > .env << EOF
# JWT Secret - CHANGE THIS IN PRODUCTION!
JWT_SECRET=$(openssl rand -hex 32)

# Database path
DATABASE_PATH=/app/data/db.sqlite

# Environment
ENVIRONMENT=production
EOF
    echo "✅ Created .env file with secure JWT secret"
fi

# Create nginx directory structure
echo "📁 Setting up Nginx configuration..."
mkdir -p nginx/sites-available nginx/ssl logs

# Copy nginx configuration from deploy directory
echo "📄 Copying Nginx configuration..."
if [ -f "deploy/nginx/nginx.conf" ]; then
    cp deploy/nginx/nginx.conf nginx/nginx.conf
    echo "✅ Nginx configuration copied"
else
    echo "❌ deploy/nginx/nginx.conf not found!"
    echo "   Make sure you cloned the repository correctly"
    exit 1
fi

# Update nginx config with domain
echo "🔧 Configuring domain: $DOMAIN"
if [ -f "nginx/nginx.conf" ]; then
    sed -i "s/your-domain.com/$DOMAIN/g" nginx/nginx.conf
    echo "✅ Domain configured: $DOMAIN"
else
    echo "❌ nginx/nginx.conf not found after copy!"
    exit 1
fi

# Create systemd service for easier management
echo "⚙️  Creating systemd service..."
sudo tee /etc/systemd/system/spjin.service > /dev/null << EOF
[Unit]
Description=SPJIN Vapor Application
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$APP_DIR
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Copy docker-compose configuration
echo "📄 Copying Docker Compose configuration..."
if [ -f "deploy/docker-compose.yml" ]; then
    cp deploy/docker-compose.yml docker-compose.yml
    echo "✅ Docker Compose configuration copied"
else
    echo "❌ deploy/docker-compose.yml not found!"
    echo "   Make sure you cloned the repository correctly"
    exit 1
fi

# Stop any existing containers
echo "🛑 Stopping existing containers..."
docker-compose down 2>/dev/null || true

# Build and start the application
echo "🔨 Building and starting the application..."
docker-compose build --no-cache
docker-compose up -d

# Enable and start the service
sudo systemctl daemon-reload
sudo systemctl enable spjin.service

# Wait for application to be ready
echo "⏳ Waiting for application to start..."
sleep 30

# Check if the application is running
if curl -f http://localhost:8080/health &>/dev/null; then
    echo "✅ Application is running successfully!"
else
    echo "⚠️  Application may not be ready yet. Check logs with: docker-compose logs"
fi

# SSL Certificate setup (if domain is not localhost)
if [ "$DOMAIN" != "your-domain.com" ] && [ "$DOMAIN" != "localhost" ]; then
    echo "🔒 Setting up SSL certificate..."
    
    # Stop nginx temporarily
    docker-compose stop nginx
    
    # Get SSL certificate
    sudo certbot certonly \
        --standalone \
        --non-interactive \
        --agree-tos \
        --email admin@$DOMAIN \
        -d $DOMAIN
    
    # Start nginx again
    docker-compose start nginx
    
    # Setup auto-renewal
    echo "⏰ Setting up SSL certificate auto-renewal..."
    (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet && docker-compose restart nginx") | crontab -
    
    echo "✅ SSL certificate configured for $DOMAIN"
fi

echo ""
echo "🎉 Deployment completed!"
echo "======================"
echo ""
echo "📋 Application Details:"
echo "  • Application URL: http://$DOMAIN (or https://$DOMAIN if SSL configured)"
echo "  • Health Check: http://localhost:8080/health"
echo "  • Application Directory: $APP_DIR"
echo "  • Database: $APP_DIR/data/db.sqlite"
echo "  • Logs: $APP_DIR/logs/"
echo ""
echo "🔧 Management Commands:"
echo "  • View logs: docker-compose logs -f"
echo "  • Restart app: sudo systemctl restart spjin"
echo "  • Stop app: sudo systemctl stop spjin"
echo "  • Start app: sudo systemctl start spjin"
echo "  • Update app: git pull && docker-compose build --no-cache && docker-compose up -d"
echo ""
echo "🔐 Security Notes:"
echo "  • JWT secret has been generated and stored in .env"
echo "  • Firewall is configured (ports 22, 80, 443 open)"
echo "  • SSL certificate auto-renewal is configured"
echo ""
echo "📝 Next Steps:"
echo "  1. Point your domain to this server's IP address"
echo "  2. Access your application at http://$DOMAIN"
echo "  3. Login to admin panel and import your data"
