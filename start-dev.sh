#!/bin/bash

# Update submodules and switch api and website to develop branch
echo "Updating submodules to develop branch..."
git submodule update --init --recursive

# Switch api to develop
echo "Switching api to develop branch..."
cd api || exit 1
if git show-ref --verify --quiet refs/heads/develop; then
    git checkout develop
else
    echo "Error: develop branch does not exist in api"
    exit 1
fi
cd ..

# Switch website to develop
echo "Switching website to develop branch..."
cd website || exit 1
if git show-ref --verify --quiet refs/heads/develop; then
    git checkout develop
else
    echo "Error: develop branch does not exist in website"
    exit 1
fi
cd ..

# Run Gradle buildImageJvm task in the api directory
echo "Building JVM image..."
cd api || exit 1
./gradlew buildImageJvm
cd ..

# Start Docker Compose development environment
echo "Starting development environment..."
docker compose -f docker-compose.dev.yml up -d

if [ $? -eq 0 ]; then
    echo "Development environment started successfully!"
else
    echo "Failed to start development environment"
    exit 1
fi

