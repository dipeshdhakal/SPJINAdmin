#!/bin/bash

# Oracle Cloud Instance Quick Commands
# Make this file executable: chmod +x oc-commands.sh

echo "Oracle Cloud SPJIN Management Commands"
echo "====================================="

case "$1" in
    "status")
        echo "📊 Application Status:"
        sudo systemctl status spjin
        echo ""
        echo "🐳 Docker Containers:"
        docker-compose ps
        ;;
        
    "logs")
        echo "📝 Application Logs:"
        docker-compose logs -f --tail=50 spjin-app
        ;;
        
    "restart")
        echo "🔄 Restarting application..."
        docker-compose restart
        sudo systemctl restart spjin
        echo "✅ Application restarted"
        ;;
        
    "update")
        echo "⬆️ Updating application..."
        git pull
        docker-compose build --no-cache
        docker-compose up -d
        echo "✅ Application updated"
        ;;
        
    "backup")
        BACKUP_DIR="/opt/spjin/backups"
        DATE=$(date +%Y%m%d_%H%M%S)
        mkdir -p $BACKUP_DIR
        
        echo "💾 Creating backup..."
        cp /opt/spjin/data/db.sqlite $BACKUP_DIR/db_backup_$DATE.sqlite
        cp /opt/spjin/.env $BACKUP_DIR/env_backup_$DATE
        
        echo "✅ Backup created: $BACKUP_DIR/db_backup_$DATE.sqlite"
        ;;
        
    "restore")
        if [ -z "$2" ]; then
            echo "❌ Please provide backup file name"
            echo "Usage: ./oc-commands.sh restore db_backup_YYYYMMDD_HHMMSS.sqlite"
            exit 1
        fi
        
        BACKUP_FILE="/opt/spjin/backups/$2"
        if [ ! -f "$BACKUP_FILE" ]; then
            echo "❌ Backup file not found: $BACKUP_FILE"
            exit 1
        fi
        
        echo "⚠️  This will replace the current database. Are you sure? (y/N)"
        read -r response
        if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
            docker-compose stop spjin-app
            cp "$BACKUP_FILE" /opt/spjin/data/db.sqlite
            docker-compose start spjin-app
            echo "✅ Database restored from $BACKUP_FILE"
        else
            echo "❌ Restore cancelled"
        fi
        ;;
        
    "ssl")
        if [ -z "$2" ]; then
            echo "❌ Please provide domain name"
            echo "Usage: ./oc-commands.sh ssl your-domain.com"
            exit 1
        fi
        
        DOMAIN="$2"
        echo "🔒 Setting up SSL for $DOMAIN..."
        
        # Update nginx config
        sed -i "s/your-domain.com/$DOMAIN/g" nginx/nginx.conf
        
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
        
        echo "✅ SSL certificate configured for $DOMAIN"
        ;;
        
    "monitor")
        echo "📊 System Resources:"
        echo "==================="
        echo "💾 Disk Usage:"
        df -h
        echo ""
        echo "🧠 Memory Usage:"
        free -h
        echo ""
        echo "⚡ CPU Usage:"
        top -bn1 | grep "Cpu(s)"
        echo ""
        echo "🐳 Docker Stats:"
        docker stats --no-stream
        ;;
        
    "clean")
        echo "🧹 Cleaning up Docker resources..."
        docker system prune -f
        docker volume prune -f
        echo "✅ Cleanup completed"
        ;;
        
    *)
        echo "Available commands:"
        echo "  status   - Show application status"
        echo "  logs     - Show application logs"
        echo "  restart  - Restart the application"
        echo "  update   - Update application from git"
        echo "  backup   - Create database backup"
        echo "  restore  - Restore database from backup"
        echo "  ssl      - Setup SSL certificate for domain"
        echo "  monitor  - Show system resource usage"
        echo "  clean    - Clean up Docker resources"
        echo ""
        echo "Usage: ./oc-commands.sh <command> [arguments]"
        ;;
esac
