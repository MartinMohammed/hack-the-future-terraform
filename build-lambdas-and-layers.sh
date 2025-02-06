#!/bin/bash
set -euo pipefail

# Create necessary directories for output
mkdir -p dist/handlers
mkdir -p dist/layers

##############################################
# Build and package Lambda handlers
##############################################
build_handlers() {
  echo "Building Lambda handlers..."

  # Loop through each handler directory in src/handlers
  for handler_dir in src/handlers/*; do
    if [ -d "$handler_dir" ]; then
      handler_name=$(basename "$handler_dir")
      echo "Processing handler: $handler_name"

      # Create a temporary build directory for the handler
      temp_dir="dist/handlers/tmp/$handler_name"
      mkdir -p "$temp_dir"

      # Copy package.json and tsconfig.json if they exist
      [ -f "$handler_dir/package.json" ] && cp "$handler_dir/package.json" "$temp_dir/"
      [ -f "$handler_dir/tsconfig.json" ] && cp "$handler_dir/tsconfig.json" "$temp_dir/"

      # Copy source files (e.g. *.ts) from the handler's src folder (if any)
      if [ -d "$handler_dir/src" ]; then
        cp "$handler_dir/src"/*.ts "$temp_dir/" 2>/dev/null || true
      fi

      # Change to the temporary directory, install dependencies, compile TS, and install only production deps
      (
        cd "$temp_dir"
        npm install
        npx tsc
        npm install --production
      )

      # Package everything from the temporary directory into a zip.
      # When unzipped, the root will contain your handler's JS files and node_modules.
      (
        cd "$temp_dir"
        zip -r "../../../handlers/$handler_name.zip" .
      )

      echo "✅ Handler '$handler_name' packaged successfully"
    fi
  done

  # Clean up temporary build files for handlers
  rm -rf dist/handlers/tmp
}

##############################################
# Build and package Lambda layers
##############################################
build_layers() {
  echo "Building Lambda layers..."

  # Loop through each layer directory in src/layers
  for layer_dir in src/layers/*; do
    if [ -d "$layer_dir" ]; then
      layer_name=$(basename "$layer_dir")
      echo "Processing layer: $layer_name"

      # Create a temporary build directory for the layer
      temp_layer_dir="dist/layers/tmp/$layer_name"
      mkdir -p "$temp_layer_dir"

      # Copy package.json and tsconfig.json if they exist
      [ -f "$layer_dir/package.json" ] && cp "$layer_dir/package.json" "$temp_layer_dir"
      [ -f "$layer_dir/tsconfig.json" ] && cp "$layer_dir/tsconfig.json" "$temp_layer_dir"

      # Copy source files (e.g. *.ts) from the layer's src folder (if any)
      if [ -d "$layer_dir/src" ]; then
        cp "$layer_dir/src"/*.ts "$temp_layer_dir" 2>/dev/null || true
      fi

      # Install dependencies, compile TS, and install only production deps
      (
        cd "$temp_layer_dir"
        npm install
        npx tsc
        npm install --production
      )

      # Create the correct folder structure for module resolution:
      # /opt/nodejs/node_modules/shared_utils
      (
        cd "$temp_layer_dir"
        mkdir -p nodejs/node_modules/shared_utils
        # Move all files (except the new nodejs folder) into nodejs/node_modules/shared_utils
        for f in *; do
          if [ "$f" != "nodejs" ]; then
            mv "$f" nodejs/node_modules/shared_utils/
          fi
        done
        # Package the contents; the resulting zip will have a top-level "nodejs" folder.
        zip -r "../../../layers/$layer_name.zip" nodejs
      )

      echo "✅ Layer '$layer_name' packaged successfully"
    fi
  done

  # Clean up temporary build files for layers
  rm -rf dist/layers/tmp
}

##############################################
# Main execution
##############################################

echo "Cleaning up previous builds..."
rm -rf dist/handlers/* dist/layers/*

build_handlers
build_layers

echo "✨ All handlers and layers have been built and packaged successfully!"
