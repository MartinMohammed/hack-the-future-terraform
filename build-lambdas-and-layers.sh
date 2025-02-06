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
    
    # Install dependencies
    echo "Installing dependencies..."
    npm ci
    
    # Build the project
    echo "Building..."
    npm run build
    
    # Prune dev dependencies
    npm prune --production
    
    # Create dist folder and copy files
    echo "Creating distribution..."
    mkdir -p dist/nodejs  # For layers, we need a nodejs directory
    
    if [ "$type" = "lambda" ]; then
        # Lambda specific packaging
        cp -r ./src/*.js dist/
        cp -r ./node_modules dist/
        
        # Create zip file in the handlers directory
        echo "Creating zip file..."
        cd dist
        zip -r "../../../src/handlers/${base_name}.zip" .
    else
        # Layer specific packaging
        cp -r ./src/*.js dist/nodejs/
        cp -r ./node_modules dist/nodejs/
        
        # Create zip file in the layers directory
        echo "Creating zip file..."
        cd dist
        zip -r "../../../src/layers/${base_name}.zip" nodejs
    fi
    
    # Clean up
    echo "Cleaning up..."
    cd ..
    rm -rf dist
    rm -rf node_modules
    
    # Go back to root
    cd ../../
    
    echo "Finished building ${base_name}"
    echo "-----------------------------------"
}

# Build Lambda functions
echo "Building Lambda functions..."
for lambda_dir in "$LAMBDAS_DIR"/*/ ; do
    if [ -d "$lambda_dir" ]; then
        build_typescript_project "$lambda_dir" "lambda"
    fi
done

# Build Layers
echo "Building Layers..."
for layer_dir in "$LAYERS_DIR"/*/ ; do
    if [ -d "$layer_dir" ]; then
        build_typescript_project "$layer_dir" "layer"
    fi
done

echo "All Lambda functions and Layers built successfully!" 