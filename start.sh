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
        echo "Usage: $0 [dev|d|prod|p|api|a|cloudflare|c] [switch|s|api|a|cloudflare|c] [api|a|cloudflare|c]"
        echo
        echo "Options:"
        echo "  dev|d        Start development environment (default)"
        echo "  prod|p       Start production environment"
        echo "  switch|s     Switch to the dev or prod branch"
        echo "  api|a        Start only the API in development mode"
        echo "  cloudflare|c Start development environment with cloudflared tunnel (default in prod environment)"
        echo
        echo "Examples:"
        echo "  $0             # Start development environment"
        echo "  $0 d           # Start development environment"
        echo "  $0 d c         # Start development environment with cloudflared"
        echo "  $0 p           # Start production environment"
        echo "  $0 p s         # Start production environment and switch to dev branch"
        echo "  $0 a           # Start only the API in development mode"
        echo "  $0 c           # Start development environment with cloudflared tunnel"
        exit 1
    fi
    START_API_ONLY=$([ "$2" = "api" ] || [ "$2" = "a" ] || [ "$3" = "api" ] || [ "$3" = "a" ] && echo "true" || echo "false")

    SWITCH_BRANCH=$([ "$2" = "switch" ] || [ "$2" = "s" ] || [ "$3" = "switch" ] || [ "$3" = "s" ] && echo "true" || echo "false")

    # Only check for cloudflare option in development environment
    if [ "$ENV_TYPE" = "dev" ]; then
        START_CLOUDFLARE=$([ "$2" = "cloudflare" ] || [ "$2" = "c" ] && echo "true" || echo "false")
    fi
fi

BRANCH_NAME=$([ "$ENV_TYPE" = "dev" ] && echo "develop" || echo "main")

# For dev environment, check if 'develop' branch exists in 'api' remote, if not, fall back to 'main'
if [[ "$ENV_TYPE" = "dev" && "$SWITCH_BRANCH" = "true" ]]; then
    cd api || exit 1
    git fetch origin --quiet
    if ! git show-ref --verify --quiet refs/remotes/origin/develop; then
        echo "Warning: 'develop' branch not found in remote 'origin' for api repository. Falling back to 'main' branch."
        BRANCH_NAME="main"
    fi
    cd ..
fi

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
if [ "$SWITCH_BRANCH" = "true" ]; then
    echo "Switching api to $BRANCH_NAME branch..."
    cd api || exit 1
    echo "Fetching updates from origin for api repository..."
    git fetch origin --quiet

    # Check if branch exists locally
    if git show-ref --verify --quiet refs/heads/$BRANCH_NAME; then
        echo "Checking out local branch $BRANCH_NAME in api..."
        if ! git checkout $BRANCH_NAME --quiet; then
            echo "Error: Failed to checkout existing local branch $BRANCH_NAME in api."
            exit 1
        fi
    # Else, check if branch exists on remote origin and create it locally
    elif git show-ref --verify --quiet refs/remotes/origin/$BRANCH_NAME; then
        echo "Local branch $BRANCH_NAME not found in api. Creating from origin/$BRANCH_NAME..."
        if ! git checkout -b $BRANCH_NAME origin/$BRANCH_NAME --quiet; then
            echo "Error: Failed to create and checkout $BRANCH_NAME from origin/$BRANCH_NAME in api."
            exit 1
        fi
    else
        echo "Error: Branch $BRANCH_NAME does not exist locally or on remote 'origin' for the api repository."
        exit 1
    fi
    cd ..

    # Only switch website branch if not starting API only
    if [ "$START_API_ONLY" = "false" ]; then
        # Switch website to appropriate branch
        echo "Switching website to $BRANCH_NAME branch..."
        cd website || exit 1
        echo "Fetching updates from origin for website repository..."
        git fetch origin --quiet

        # Check if branch exists locally
        if git show-ref --verify --quiet refs/heads/$BRANCH_NAME; then
            echo "Checking out local branch $BRANCH_NAME in website..."
            if ! git checkout $BRANCH_NAME --quiet; then
                echo "Error: Failed to checkout existing local branch $BRANCH_NAME in website."
                exit 1
            fi
        # Else, check if branch exists on remote origin and create it locally
        elif git show-ref --verify --quiet refs/remotes/origin/$BRANCH_NAME; then
            echo "Local branch $BRANCH_NAME not found in website. Creating from origin/$BRANCH_NAME..."
            if ! git checkout -b $BRANCH_NAME origin/$BRANCH_NAME --quiet; then
                echo "Error: Failed to create and checkout $BRANCH_NAME from origin/$BRANCH_NAME in website."
                exit 1
            fi
        else
            echo "Error: Branch $BRANCH_NAME does not exist locally or on remote 'origin' for the website repository."
            exit 1
        fi
        cd ..
    fi
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

# Load frontend environment variables in production
if [ "$ENV_TYPE" = "prod" ]; then
    FRONTEND_ENV="private/frontend/.env"
    if [ -f "$FRONTEND_ENV" ]; then
        echo "Loading frontend env from: $FRONTEND_ENV"
        set -a
        source "$FRONTEND_ENV"
        set +a
    else
        echo "Warning: Frontend .env file not found at $FRONTEND_ENV"
    fi
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