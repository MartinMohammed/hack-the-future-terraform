#!/bin/bash

# Exit on any error
set -e

# Directory containing all lambda functions
LAMBDAS_DIR="lambdas"

# Create src directory if it doesn't exist
mkdir -p src

# Find all directories in the lambdas folder
for lambda_dir in "$LAMBDAS_DIR"/*/ ; do
    if [ -d "$lambda_dir" ]; then
        echo "Building Lambda function in $lambda_dir"
        
        # Navigate to the lambda directory
        cd "$lambda_dir"
        
        # Install dependencies
        echo "Installing dependencies..."
        npm ci
        
        # Build the lambda
        echo "Building..."
        npm run build
        
        # Prune dev dependencies
        npm prune --production
        
        # Create dist folder and copy files
        echo "Creating distribution..."
        mkdir -p dist
        cp -r ./src/*.js dist/
        cp -r ./node_modules dist/
        
        # Create zip file
        echo "Creating zip file..."
        cd dist
        find . -name "*.zip" -type f -delete
        zip -r "../../../src/$(basename $lambda_dir).zip" .
        
        # Clean up
        echo "Cleaning up..."
        cd ..
        rm -rf dist
        rm -rf node_modules
        
        # Go back to root
        cd ../../
        
        echo "Finished building $(basename $lambda_dir)"
        echo "-----------------------------------"
    fi
done

echo "All Lambda functions built successfully!" 