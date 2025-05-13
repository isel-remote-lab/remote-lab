#!/bin/bash

# Check if environment type is provided
if [ "$1" != "dev" ] && [ "$1" != "prod" ]; then
    echo "Usage: $0 [dev|prod]"
    echo "Please specify either 'dev' or 'prod' as an argument"
    exit 1
fi

ENV_TYPE=$1
BRANCH_NAME=$([ "$ENV_TYPE" = "dev" ] && echo "develop" || echo "main")

# Set environment variables for Docker Compose
export ENV_TYPE
if [ "$ENV_TYPE" = "prod" ]; then
    export DOCKERFILE="Dockerfile"
    # In production, we don't mount the website directory
    export WEBSITE_VOLUME=""
    export NODE_MODULES_VOLUME=""
else
    export DOCKERFILE="Dockerfile.dev"
    export WEBSITE_VOLUME="./website:/app"
    export NODE_MODULES_VOLUME="/app/node_modules"
fi

# Switch api to appropriate branch
echo "Switching api to $BRANCH_NAME branch..."
cd api || exit 1
if git show-ref --verify --quiet refs/heads/$BRANCH_NAME; then
    echo "Checking out $BRANCH_NAME branch..."
    git checkout $BRANCH_NAME
else
    echo "Error: $BRANCH_NAME branch does not exist in api"
    exit 1
fi
cd ..

# Switch website to appropriate branch
echo "Switching website to $BRANCH_NAME branch..."
cd website || exit 1
if git show-ref --verify --quiet refs/heads/$BRANCH_NAME; then
    git checkout $BRANCH_NAME
else
    echo "Error: $BRANCH_NAME branch does not exist in website"
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
        echo "Error: .env file not found in $SECRETS_DIR"
        exit 1
    fi
else
    echo "Error: Secrets directory $SECRETS_DIR does not exist"
    exit 1
fi

# Check for environment file
FRONTEND_ENV="private/frontend/.env.$([ "$ENV_TYPE" = "dev" ] && echo "local" || echo "production")"
if [ ! -f "$FRONTEND_ENV" ]; then
    echo "Error: Environment file not found at $FRONTEND_ENV"
    exit 1
fi

# Start Docker Compose environment
echo "Starting $ENV_TYPE environment..."
docker compose up --build -d

if [ $? -eq 0 ]; then
    echo "$ENV_TYPE environment started successfully!"
else
    echo "Failed to start $ENV_TYPE environment"
    exit 1
fi

# Show the logs of all the containers
docker compose logs -f 