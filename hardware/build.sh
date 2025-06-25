#!/bin/bash

# Force x86_64 platform for all builds
export DOCKER_DEFAULT_PLATFORM=linux/amd64

echo "Building rl-websocket binary for x86_64..."

# Clean previous builds
rm -rf dist build

# Build binary for x86_64
pyinstaller rl-websocket.spec

echo "Binary built successfully!"

echo "Building Docker image for x86_64..."
docker build --platform linux/amd64 -t rl-websocket:latest .

echo "Docker image built successfully!"
echo "You can now run: docker run --platform linux/amd64 rl-websocket:latest" 