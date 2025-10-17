#!/bin/bash -ex
# Script to extract Unity Licensing Server from Unity Hub macOS .dmg package (run on Linux)

# Usage check
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <architecture> (x64 or arm64)"
    echo "Example: $0 arm64"
    exit 1
fi

ARCH="$1"
URL="https://public-cdn.cloud.unity3d.com/hub/prod/UnityHubSetup-${ARCH}.dmg"
DMG_FILE="UnityHubSetup-${ARCH}.dmg"
EXTRACT_DIR="unityhub_macos_extracted"
OUTPUT_DIR="unity_licensing_server_macos"

# Clean up function
cleanup() {
    rm -rf "$DMG_FILE" "$IMG_FILE" "$EXTRACT_DIR" 2>/dev/null || true
}
trap cleanup EXIT

echo "Downloading Unity Hub for macOS ($ARCH)"
# Download the .dmg file
wget -O "$DMG_FILE" "$URL"

echo "Extracting .dmg file $(basename $DMG_FILE)"
# Create extraction directories
mkdir -p "$EXTRACT_DIR" "$OUTPUT_DIR"


# Convert the .dmg to .img (requires dmg2img)
IMG_FILE="UnityHubSetup-${ARCH}.img"
dmg2img "$DMG_FILE" "$IMG_FILE"

# Extract the .img file using 7z (requires p7zip-full)
7z x "$IMG_FILE" -y -o"$EXTRACT_DIR" || true # 7zip fails, but it still extracts the licensing client  

# Locate the folder containing Unity.Licensing.Client executable
CLIENT_EXE=$(find "$EXTRACT_DIR" -type f -iname "Unity.Licensing.Client" | head -n 1)
if [ -n "$CLIENT_EXE" ]; then
    CLIENT_DIR=$(dirname "$CLIENT_EXE")
    cp -r "$CLIENT_DIR" "$OUTPUT_DIR/"
    echo "Unity License Client installation folder copied to $OUTPUT_DIR/$(basename "$CLIENT_DIR")"
    
    # Read the Licensing Client version from deps.json file
    DEPS_JSON="$OUTPUT_DIR/$(basename "$CLIENT_DIR")/Unity.Licensing.Client.deps.json"
    if [ -f "$DEPS_JSON" ]; then
        # Extract everything between "Unity.Licensing.Client/" and the next quote
        VERSION=$(grep -m 1 "Unity.Licensing.Client/" "$DEPS_JSON" | sed -n 's/.*Unity.Licensing.Client\/\([^"]*\).*/\1/p')
    fi
    if [ -z "$VERSION" ]; then
        echo "Could not calculate licensing client version"
        exit 2 
    fi
    printf "%s" "$VERSION" >> ulc_version_macos-${ARCH}
    # Bundle everything in a zip file
    ZIP_NAME="UnityLicensingClient-macOS-${ARCH}-${VERSION}.zip"
    zip -r "$ZIP_NAME" "$OUTPUT_DIR" > /dev/null
    echo "Bundled licensing client in $ZIP_NAME"
else
    echo "Unity.Licensing.Client executable not found in the package."
    exit 1
fi