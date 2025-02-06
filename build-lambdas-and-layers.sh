#!/bin/bash

# Exit on any error
set -e

# Directory containing all lambda functions and layers
LAMBDAS_DIR="lambdas"
LAYERS_DIR="layers"

# Create src directory structure if it doesn't exist
mkdir -p src/handlers
mkdir -p src/layers

# Function to build TypeScript projects
build_typescript_project() {
    local dir=$1
    local type=$2  # "lambda" or "layer"
    local base_name=$(basename "$dir")
    
    echo "Building $type in $dir"
    
    # Navigate to the directory
    cd "$dir"
    
    # Install all dependencies (both prod and dev)
    echo "Installing dependencies..."
    npm ci
    
    # Build the project
    echo "Building..."
    npm run build
    
    if [ "$type" = "lambda" ]; then
        # Lambda specific packaging - include the compiled code
        mkdir -p "../src/handlers/${base_name}"
        cp -r ./src/*.js "../src/handlers/${base_name}/"
        
        # Create zip file in the handlers directory
        cd "../src/handlers/${base_name}"
        zip -r "../${base_name}.zip" .
        cd ../../../
        
    else
        # Layer specific packaging - include the compiled code and node_modules
        mkdir -p dist/nodejs
        cp -r ./src/*.js dist/nodejs/
        cp -r ./node_modules dist/nodejs/
        
        # Create zip file in the layers directory
        cd dist
        zip -r "../../../src/layers/${base_name}.zip" nodejs
        cd ..
    fi
    
    # Clean up
    rm -rf dist
    rm -rf node_modules
    
    # Go back to root
    cd ../../
    
    echo "Finished building ${base_name}"
    echo "-----------------------------------"
}

# Build the utils layer
echo "Building utils layer..."
build_typescript_project "${LAYERS_DIR}/util-layer" "layer"

# Build the tariff handler lambda
echo "Building tariff handler lambda..."
build_typescript_project "${LAMBDAS_DIR}/tariff_handler" "lambda"

echo "Build completed successfully!" 