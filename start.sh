#!/bin/bash

# Check if first argument is 'api'
if [ "$1" = "api" ] || [ "$1" = "a" ]; then
    ENV_TYPE="dev"
    START_API_ONLY="true"
    START_CLOUDFLARE="false"
    echo "Starting API only in development environment..."
elif [ "$1" = "cloudflare" ] || [ "$1" = "c" ]; then
    ENV_TYPE="dev"
    START_API_ONLY="false"
    START_CLOUDFLARE="true"
    echo "Starting development environment with cloudflared tunnel..."
else
    # Set default environment type to dev if not provided
    ENV_TYPE=${1:-dev}
    if [ "$ENV_TYPE" != "dev" ] && [ "$ENV_TYPE" != "prod" ]; then
        echo "Usage: $0 [dev|d|prod|p|api|a|cloudflare|c] [api|a|cloudflare|c]"
        echo
        echo "Options:"
        echo "  dev|d        Start development environment (default)"
        echo "  prod|p       Start production environment"
        echo "  api|a        Start only the API in development mode"
        echo "  cloudflare|c Start development environment with cloudflared tunnel"
        echo
        echo "Examples:"
        echo "  $0             # Start development environment"
        echo "  $0 d           # Start development environment"
        echo "  $0 d c         # Start development environment with cloudflared"
        echo "  $0 p           # Start production environment"
        echo "  $0 a           # Start only the API in development mode"
        echo "  $0 c           # Start development environment with cloudflared tunnel"
        exit 1
    fi
    START_API_ONLY=$([ "$2" = "api" ] && echo "true" || echo "false")
    # Only check for cloudflare option in development environment
    if [ "$ENV_TYPE" = "dev" ]; then
        START_CLOUDFLARE=$([ "$2" = "cloudflare" ] || [ "$2" = "c" ] && echo "true" || echo "false")
    fi
fi

BRANCH_NAME=$([ "$ENV_TYPE" = "dev" ] && echo "develop" || echo "main")

# Set environment variables for Docker Compose
export ENV_TYPE
if [ "$ENV_TYPE" = "prod" ]; then
    # In production, we don't mount the website directory
    export WEBSITE_VOLUME=""
    export NODE_MODULES_VOLUME=""
else
    # Expose the database port to the host machine in dev environment
    export DB_PORT="5432"
    export WEBSITE_VOLUME="./website:/app"
    export NODE_MODULES_VOLUME="/app/node_modules"
fi

# Set API port if starting API only
if [ "$START_API_ONLY" = "true" ]; then
    export API_PORT="8080"
else
    export API_PORT=""
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

# Only switch website branch if not starting API only
if [ "$START_API_ONLY" = "false" ]; then
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
fi

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

# Set NEXTAUTH_URL based on START_CLOUDFLARE
if [ "$START_CLOUDFLARE" = "true" ]; then
    export NEXTAUTH_URL="$URL"
else
    export NEXTAUTH_URL="http://localhost"
fi

# Start Docker Compose environment
echo "Starting $ENV_TYPE environment..."
command="docker compose"
if [ "$START_API_ONLY" = "true" ]; then
    command="$command --profile api"
else 
    command="$command --profile full"
fi
if [ "$ENV_TYPE" = "prod" ]; then
    command="$command --profile prod"
fi    
if [ "$START_CLOUDFLARE" = "true" ]; then
    command="$command --profile cloudflare"
fi
$command up --build -d

if [ $? -eq 0 ]; then
    echo "$ENV_TYPE environment started successfully!"
else
    echo "Failed to start $ENV_TYPE environment"
    exit 1
fi

# Show the logs of all the containers
$command logs -f