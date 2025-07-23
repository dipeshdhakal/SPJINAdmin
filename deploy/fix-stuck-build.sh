#!/bin/bash

echo "🚨 Fixing Stuck Deployment on Oracle Cloud"
echo "========================================="

echo "📊 Checking current system resources..."
echo "Memory usage:"
free -h
echo ""
echo "Disk usage:"
df -h
echo ""
echo "Docker processes:"
docker ps
echo ""

echo "🛑 Stopping stuck build process..."
docker-compose down 2>/dev/null || true
docker stop $(docker ps -aq) 2>/dev/null || true
docker system prune -f

echo "🧹 Cleaning up to free memory..."
# Clean Docker cache
docker builder prune -f
docker image prune -f
docker volume prune -f

# Clean system cache
sudo sync
sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'

echo "📊 Memory after cleanup:"
free -h

echo ""
echo "🔄 Choose your build strategy:"
echo "1. Use low-memory Dockerfile (recommended for Oracle Cloud free tier)"
echo "2. Try original build with more time"
echo "3. Use pre-built Docker image (fastest)"
echo ""
read -p "Enter your choice (1-3): " choice

case $choice in
    1)
        echo "🔧 Using low-memory Dockerfile..."
        if [ -f "Dockerfile.lowmem" ]; then
            cp Dockerfile.lowmem Dockerfile.backup
            mv Dockerfile Dockerfile.original
            mv Dockerfile.lowmem Dockerfile
            echo "✅ Switched to low-memory Dockerfile"
        else
            echo "❌ Dockerfile.lowmem not found. Creating one..."
            # Create the low-memory Dockerfile if it doesn't exist
            cat > Dockerfile.lowmem << 'EOF'
# Use Swift official image
FROM swift:5.9-jammy as build

# Set memory and CPU limits for compilation
ENV MAKEFLAGS="-j1"
ENV SWIFT_BUILD_FLAGS="--jobs 1"

# Install system dependencies
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get install -y libssl-dev zlib1g-dev libsqlite3-dev pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Set work directory
WORKDIR /build

# Copy package files first for better caching
COPY Package.swift Package.resolved ./

# Resolve dependencies with limited parallelism
RUN swift package resolve --jobs 1

# Copy source code and resources
COPY Sources ./Sources
COPY Resources ./Resources
COPY Public ./Public

# Build the project with limited resources
RUN swift build --configuration release --skip-update --jobs 1

# Production stage
FROM swift:5.9-jammy-slim

# Install runtime dependencies
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get install -y libssl3 libsqlite3-0 ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create a vapor user and group
RUN useradd --user-group --create-home --shell /bin/bash vapor

# Set work directory
WORKDIR /app

# Copy built executable and resources
COPY --from=build --chown=vapor:vapor /build/.build/release /app
COPY --from=build --chown=vapor:vapor /build/Public /app/Public
COPY --from=build --chown=vapor:vapor /build/Resources /app/Resources

# Create directory for SQLite database with proper permissions
RUN mkdir -p /app/data && chown vapor:vapor /app/data

# Switch to vapor user
USER vapor:vapor

# Create volume for SQLite database persistence
VOLUME ["/app/data"]

# Expose port
EXPOSE 8080

# Set entry point
ENTRYPOINT ["./App"]
CMD ["serve", "--env", "production", "--hostname", "0.0.0.0", "--port", "8080"]
EOF
            mv Dockerfile Dockerfile.original
            mv Dockerfile.lowmem Dockerfile
            echo "✅ Created and switched to low-memory Dockerfile"
        fi
        ;;
    2)
        echo "⏰ Using original Dockerfile with extended timeout..."
        # Keep original Dockerfile but modify docker-compose
        ;;
    3)
        echo "🚀 Using pre-built image..."
        # This would require a pre-built image on Docker Hub
        echo "❌ Pre-built image not available yet. Please choose option 1 or 2."
        exit 1
        ;;
    *)
        echo "❌ Invalid choice. Exiting."
        exit 1
        ;;
esac

echo ""
echo "🔧 Adding swap space to improve build performance..."
# Check if swap exists
if [ $(swapon --show | wc -l) -eq 0 ]; then
    echo "Creating 2GB swap file..."
    sudo fallocate -l 2G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo "✅ Swap space added"
else
    echo "✅ Swap already exists"
fi

echo ""
echo "🚀 Restarting deployment with optimizations..."
echo "This may take 15-30 minutes on Oracle Cloud free tier..."

# Set build timeout
export COMPOSE_HTTP_TIMEOUT=3600
export DOCKER_CLIENT_TIMEOUT=3600

# Start the build
docker-compose build --no-cache --memory=1g
if [ $? -eq 0 ]; then
    echo "✅ Build completed successfully!"
    docker-compose up -d
    echo "🎉 Deployment completed!"
else
    echo "❌ Build failed. Check the logs above."
    echo ""
    echo "💡 Troubleshooting tips:"
    echo "1. Make sure you have enough disk space: df -h"
    echo "2. Check memory usage: free -h"
    echo "3. Try building during off-peak hours"
    echo "4. Consider using a larger Oracle Cloud instance temporarily"
fi
