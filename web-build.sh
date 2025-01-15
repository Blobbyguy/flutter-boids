#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

sudo snap install flutter --classic

# Build the Flutter web project
flutter build web

# Navigate to the build directory
cd build/web

echo "Deployment to Cloudflare completed successfully."