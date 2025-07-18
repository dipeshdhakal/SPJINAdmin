#!/bin/bash

set -e

echo "Starting build process..."

# Resolve dependencies
echo "Resolving Swift package dependencies..."
swift package resolve

# Build the project
echo "Building Swift project..."
swift build --configuration release --verbose

echo "Build completed successfully!"
