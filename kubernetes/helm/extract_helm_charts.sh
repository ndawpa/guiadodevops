#!/bin/bash

# Script to extract all .tgz files in the helm folder
# This script will extract each .tgz file to a directory with the same name (without .tgz extension)

set -e  # Exit on any error

# Change to the helm directory
cd "$(dirname "$0")"

echo "Starting extraction of Helm charts..."

# Counter for processed files
processed=0
total=$(find . -maxdepth 1 -name "*.tgz" | wc -l)

# Process each .tgz file
for file in *.tgz; do
    # Check if file exists (in case no .tgz files are found)
    if [ ! -f "$file" ]; then
        echo "No .tgz files found in current directory."
        exit 1
    fi
    
    # Get the base name without .tgz extension
    base_name="${file%.tgz}"
    
    echo "[$((++processed))/$total] Extracting $file to $base_name/"
    
    # Create directory if it doesn't exist
    mkdir -p "$base_name"
    
    # Extract the .tgz file to the directory
    tar -xzf "$file" -C "$base_name"
    
    echo "✓ Successfully extracted $file"
done

echo ""
echo "✅ Extraction complete! All $total Helm charts have been extracted."
echo "Each chart is now in its own directory with the same name as the original .tgz file." 