#!/bin/bash

# Create necessary directories
mkdir -p dist/handlers
mkdir -p dist/layers

# Function to build and package Lambda handlers
build_handlers() {
    echo "Building Lambda handlers..."
    
    # Loop through each handler directory
    for handler_dir in src/handlers/*; do
        if [ -d "$handler_dir" ]; then
            handler_name=$(basename "$handler_dir")
            echo "Processing handler: $handler_name"
            
            # Create temporary build directory
            mkdir -p "dist/handlers/tmp/$handler_name"
            
            # Copy package.json if it exists
            if [ -f "$handler_dir/package.json" ]; then
                cp "$handler_dir/package.json" "dist/handlers/tmp/$handler_name/"
                
                # Install dependencies
                (cd "dist/handlers/tmp/$handler_name" && npm install --production)
            fi
            
            # Copy all .js, .ts files
            cp -r "$handler_dir"/*.{js,ts} "dist/handlers/tmp/$handler_name/" 2>/dev/null || true
            
            # Create zip file
            (cd "dist/handlers/tmp/$handler_name" && zip -r "../../$handler_name.zip" .)
            
            echo "✅ Handler $handler_name packaged successfully"
        fi
    done
    
    # Clean up temporary build directory
    rm -rf "dist/handlers/tmp"
}

# Function to build and package Lambda layers
build_layers() {
    echo "Building Lambda layers..."
    
    # Loop through each layer directory
    for layer_dir in src/layers/*; do
        if [ -d "$layer_dir" ]; then
            layer_name=$(basename "$layer_dir")
            echo "Processing layer: $layer_name"
            
            # Create temporary build directory with nodejs structure
            mkdir -p "dist/layers/tmp/$layer_name/nodejs"
            
            # Copy package.json if it exists
            if [ -f "$layer_dir/package.json" ]; then
                cp "$layer_dir/package.json" "dist/layers/tmp/$layer_name/nodejs/"
                
                # Install dependencies
                (cd "dist/layers/tmp/$layer_name/nodejs" && npm install --production)
            fi
            
            # Copy all .js, .ts files
            cp -r "$layer_dir/src"/*.{js,ts} "dist/layers/tmp/$layer_name/nodejs/" 2>/dev/null || true
            
            # Create zip file
            (cd "dist/layers/tmp/$layer_name" && zip -r "../../$layer_name.zip" .)
            
            echo "✅ Layer $layer_name packaged successfully"
        fi
    done
    
    # Clean up temporary build directory
    rm -rf "dist/layers/tmp"
}

# Clean up previous builds
echo "Cleaning up previous builds..."
rm -rf dist/handlers/* dist/layers/*

# Execute build functions
build_handlers
build_layers

echo "✨ All handlers and layers have been built and packaged successfully!"
