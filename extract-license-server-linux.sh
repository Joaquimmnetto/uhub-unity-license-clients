#!/bin/bash
# Script to extract Unity Licensing Server from the latest Unity Hub .deb package

set -e

REPO_URL="https://hub.unity3d.com/linux/repos/deb"
PACKAGES_URL="$REPO_URL/dists/stable/main/binary-amd64/Packages"

DEB_FILE=""
EXTRACT_DIR="unityhub_extracted"
OUTPUT_DIR="unity_licensing_server"

cleanup() {
    rm -rf "$DEB_FILE" Packages "$EXTRACT_DIR" "$OUTPUT_DIR" 2>/dev/null || true
}
trap cleanup EXIT

# Download the Packages file
wget -qO Packages "$PACKAGES_URL"

# Extract the latest unityhub .deb filename (last occurrence)
DEB_PATH=$(awk '/^Package: unityhub$/{f=1} f && /^Filename: /{print $2; f=0}' Packages | tail -n 1)

if [ -z "$DEB_PATH" ]; then
    echo "Could not find unityhub .deb in Packages file."
    exit 1
fi

# Download the .deb file
wget "$REPO_URL/$DEB_PATH"

echo "Downloaded: $(basename "$DEB_PATH")"
DEB_FILE=$(basename "$DEB_PATH")

EXTRACT_DIR="unityhub_extracted"
OUTPUT_DIR="unity_licensing_server"

echo "Extracting .deb file $(basename $DEB_FILE)"
# Create extraction directories
mkdir -p "$EXTRACT_DIR" "$OUTPUT_DIR"

# Extract the .deb file
ar x "$DEB_FILE" --output "$EXTRACT_DIR"

# Extract data.tar.* (could be .xz, .gz, etc.)
DATA_TAR=$(ls "$EXTRACT_DIR"/data.tar.* | head -n 1)
tar -xf "$DATA_TAR" -C "$EXTRACT_DIR"

# Locate the folder containing Unity.Licensing.Client executable
CLIENT_EXE=$(find "$EXTRACT_DIR" -type f -iname "Unity.Licensing.Client" | head -n 1)
if [ -n "$CLIENT_EXE" ]; then
    CLIENT_DIR=$(dirname "$CLIENT_EXE")
    cp -r "$CLIENT_DIR" "$OUTPUT_DIR/"
    echo "Unity License Client installation folder copied to $OUTPUT_DIR/$(basename "$CLIENT_DIR")"
    
    # Read the Licensing Client version from deps.json file
    DEPS_JSON="$CLIENT_DIR/Unity.Licensing.Client.deps.json"
    if [ -f "$DEPS_JSON" ]; then
        # Extract everything between "Unity.Licensing.Client/" and the next quote
        VERSION=$(grep -m 1 "Unity.Licensing.Client/" "$DEPS_JSON" | sed -n 's/.*Unity.Licensing.Client\/\([^"]*\).*/\1/p')
    fi
    if [ -z "$VERSION" ]; then
        echo "Could not calculate licensing client version"
        exit 2 
    fi
    printf "%s" "$VERSION" >> ulc_version_linux
    # Bundle everything in a zip file
    ZIP_NAME="UnityLicensingClient-${VERSION}.zip"
    zip -r "$ZIP_NAME" "$OUTPUT_DIR" > /dev/null
    echo "Bundled licensing client in $ZIP_NAME"
else
    echo "Unity.Licensing.Client executable not found in the package."
    exit 1
fi
