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

# Run Gradle build and buildImageJvm task in the api directory
echo "Building JVM image..."
cd api || exit 1
./gradlew build buildImageJvm
cd ..

# Start Docker Compose development environment
echo "Starting development environment..."
docker-compose -f docker-compose.dev.yml up -d

echo "Development environment started successfully!" 