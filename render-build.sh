#!/bin/bash

set -e

echo "Installing Swift..."
# Install Swift if not available
if ! command -v swift &> /dev/null; then
    echo "Swift not found, installing..."
    # Render will provide Swift in their environment
fi

echo "Building Swift project..."
swift build --configuration release

echo "Running migrations..."
./.build/release/App migrate --yes

echo "Build complete!"
