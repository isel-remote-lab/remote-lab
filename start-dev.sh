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

# Load environment variables from secrets directory
echo "Loading environment variables from secrets..."
SECRETS_DIR="private/shared/secrets"
ENV_FILE="$SECRETS_DIR/.env"

if [ -d "$SECRETS_DIR" ]; then
    if [ -f "$ENV_FILE" ]; then
        echo "Loading secrets from: $ENV_FILE"
        set -a
        source "$ENV_FILE"
        set +a
    else
        echo "Warning: .env file not found in $SECRETS_DIR"
    fi
else
    echo "Warning: Secrets directory $SECRETS_DIR does not exist"
fi

# Start Docker Compose development environment
echo "Starting development environment..."
docker compose -f docker-compose.dev.yml up -d

if [ $? -eq 0 ]; then
    echo "Development environment started successfully!"
else
    echo "Failed to start development environment"
    exit 1
fi

