#!/bin/bash
# Script to extract Unity Licensing Server from Unity Hub .deb package

set -e

# Usage check
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <unity_hub_version>"
    echo "Example: $0 3.12.1"
    exit 1
fi

VERSION="$1"
URL="https://public-cdn.cloud.unity3d.com/hub/${VERSION}/unityhub-amd64-${VERSION}.deb"
DEB_FILE="unityhub-amd64-${VERSION}.deb"
EXTRACT_DIR="unityhub_extracted"
OUTPUT_DIR="unity_licensing_server"

# Download the .deb file
wget -O "$DEB_FILE" "$URL"

# Create extraction directories
mkdir -p "$EXTRACT_DIR" "$OUTPUT_DIR"

# Extract the .deb file
ar x "$DEB_FILE" --output "$EXTRACT_DIR"

# Extract data.tar.* (could be .xz, .gz, etc.)
DATA_TAR=$(ls "$EXTRACT_DIR"/data.tar.* | head -n 1)
tar -xf "$DATA_TAR" -C "$EXTRACT_DIR"

# Locate the folder containing Unity.Licensing.Server executable
SERVER_EXE=$(find "$EXTRACT_DIR" -type f -name "Unity.Licensing.Server" | head -n 1)
if [ -n "$SERVER_EXE" ]; then
    SERVER_DIR=$(dirname "$SERVER_EXE")
    cp -r "$SERVER_DIR" "$OUTPUT_DIR/"
    echo "Unity License Server installation folder copied to $OUTPUT_DIR/$(basename "$SERVER_DIR")"
else
    echo "Unity.Licensing.Server executable not found in the package."
fi
