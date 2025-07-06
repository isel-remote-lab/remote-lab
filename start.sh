#!/bin/bash

# Initialize variables
ENV_TYPE="dev"
START_API_ONLY="false"
START_CLOUDFLARE="false"
DEMO_MODE="false"

# Parse arguments
for arg in "$@"; do
    case "$arg" in
        -api|-a)
            START_API_ONLY="true"
            ENV_TYPE="dev"
            ;;
        -cloudflare|-c)
            START_CLOUDFLARE="true"
            ;;
        -demo|-dm)
            DEMO_MODE="true"
            ;;
        -dev|-d)
            ENV_TYPE="dev"
            START_API_ONLY="false"
            ;;
        -prod|-p)
            ENV_TYPE="prod"
            START_API_ONLY="false"
            ;;
        -logs|-l)
            # Show logs without restarting
            docker compose logs -f
            exit 0
            ;;
        -switch|-s)
            SWITCH_BRANCH="true"
            ;;
        "")
            # Default case - do nothing
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Usage: $0 [-dev|-d|-prod|-p|-api|-a] [-cloudflare|-c] [-demo|-dm] [-switch|-s] [-logs|-l]"
            echo
            echo "Options:"
            echo "  -dev|-d       Start development environment (default)"
            echo "  -prod|-p      Start production environment"
            echo "  -api|-a       Start only the API in development mode"
            echo "  -cloudflare|-c Start with cloudflared tunnel"
            echo "  -demo|-dm     Enable demo mode (use with dev/prod/api) or run dev with cloudflare if used alone"
            echo "  -switch|-s    Switch to the appropriate branch"
            echo "  -logs|-l      Show logs without restarting containers"
            echo
            echo "Examples:"
            echo "  $0             # Start development environment"
            echo "  $0 -dev        # Start development environment"
            echo "  $0 -d          # Start development environment (short)"
            echo "  $0 -dm         # Start development environment with cloudflare (demo shortcut)"
            echo "  $0 -dev -dm    # Start development environment in demo mode"
            echo "  $0 -d -dm      # Start development environment in demo mode (short)"
            echo "  $0 -prod -dm   # Start production environment in demo mode"
            echo "  $0 -p -dm      # Start production environment in demo mode (short)"
            echo "  $0 -api -dm    # Start only API in demo mode"
            echo "  $0 -a -dm      # Start only API in demo mode (short)"
            echo "  $0 -dev -c     # Start development environment with cloudflared"
            echo "  $0 -d -c       # Start development environment with cloudflared (short)"
            echo "  $0 -prod -s    # Start production environment and switch branch"
            echo "  $0 -p -s       # Start production environment and switch branch (short)"
            echo "  $0 -l          # Show logs"
            exit 1
            ;;
    esac
done

# Special case: if only -dm is used, run dev with cloudflare and demo mode
if [ "$DEMO_MODE" = "true" ] && [ "$ENV_TYPE" = "dev" ] && [ "$START_API_ONLY" = "false" ] && [ "$START_CLOUDFLARE" = "false" ] && [ "$#" -eq 1 ]; then
    echo "Demo mode shortcut detected: Starting development environment with cloudflare and demo mode..."
    START_CLOUDFLARE="true"
    # Keep DEMO_MODE="true" to enable the demo profile for hardware-example
fi

# Validate demo mode usage - demo cannot be used alone (except for the shortcut above)
if [ "$DEMO_MODE" = "true" ]; then
    # Check if demo is used with only cloudflare or other modifiers
    if [ "$ENV_TYPE" = "dev" ] && [ "$START_API_ONLY" = "false" ] && [ "$START_CLOUDFLARE" = "true" ] && [ "$#" -eq 2 ]; then
        echo "Error: Demo mode (-demo/-dm) must be used with an environment type, not just modifiers."
        echo
        echo "Examples:"
        echo "  $0 -dev -dm -c    # Development environment in demo mode with cloudflare"
        echo "  $0 -prod -dm -s   # Production environment in demo mode with branch switch"
        echo "  $0 -api -dm       # API only in demo mode"
        exit 1
    fi
fi

# Display status message based on configuration
if [ "$DEMO_MODE" = "true" ] && [ "$ENV_TYPE" = "dev" ] && [ "$START_API_ONLY" = "false" ]; then
    echo "Starting development environment in demo mode..."
elif [ "$DEMO_MODE" = "true" ] && [ "$ENV_TYPE" = "prod" ]; then
    echo "Starting production environment in demo mode..."
elif [ "$DEMO_MODE" = "true" ] && [ "$START_API_ONLY" = "true" ]; then
    echo "Starting API only in demo mode..."
elif [ "$DEMO_MODE" = "true" ]; then
    echo "Starting $ENV_TYPE environment in demo mode..."
elif [ "$START_API_ONLY" = "true" ]; then
    echo "Starting API only in development environment..."
elif [ "$START_CLOUDFLARE" = "true" ] && [ "$ENV_TYPE" = "dev" ]; then
    echo "Starting development environment with cloudflared tunnel..."
elif [ "$ENV_TYPE" = "prod" ]; then
    echo "Starting production environment..."
else
    echo "Starting development environment..."
fi

# Set branch name based on environment and demo mode
if [ "$DEMO_MODE" = "true" ]; then
    BRANCH_NAME="demo"
elif [ "$ENV_TYPE" = "dev" ]; then
    BRANCH_NAME="develop"
else
    BRANCH_NAME="main"
fi

# For dev environment, check if 'develop' branch exists in 'api' remote, if not, fall back to 'main'
if [[ "$ENV_TYPE" = "dev" && "$SWITCH_BRANCH" = "true" && "$DEMO_MODE" = "false" ]]; then
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
if [ "$ENV_TYPE" = "dev" ] || [ "$DEMO_MODE" = "true" ]; then
    export WEBSITE_DEV_FOLDER="./website/"
else
    # Don't expose the database port in prod environment
    export DB_PORT=""
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
if [ "$ENV_TYPE" = "dev" ]; then
    command="$command --profile dev"
fi
if [ "$ENV_TYPE" = "prod" ]; then
    command="$command --profile prod"
fi    
if [ "$DEMO_MODE" = "true" ]; then
    command="$command --profile demo"
fi
if [ "$START_CLOUDFLARE" = "true" ]; then
    command="$command --profile cloudflare"
fi

# Enable Docker Compose Bake for faster builds
export COMPOSE_BAKE=1

$command up -d --build

if [ $? -eq 0 ]; then
    if [ "$DEMO_MODE" = "true" ]; then
        echo "$ENV_TYPE environment started successfully in demo mode!"
    else
        echo "$ENV_TYPE environment started successfully!"
    fi
else
    echo "Failed to start $ENV_TYPE environment"
    exit 1
fi

# Show the logs of all the containers
$command logs -f