#!/usr/bin/env bash
set -euo pipefail

# Navigate to the script's directory
cd "$(dirname "$0")"

FLAKE_FILE="flake.nix"
MANIFEST_URL="https://proton.me/download/pass-cli/versions.json"

if [ ! -f "$FLAKE_FILE" ]; then
    echo "Error: $FLAKE_FILE not found in current directory."
    exit 1
fi

# Fetch manifest
echo "Fetching manifest..."
MANIFEST=$(curl -fsSL "$MANIFEST_URL")

# Get version
VERSION=$(echo "$MANIFEST" | jq -r '.passCliVersions.version')
echo "Latest version: $VERSION"

# Update Version in flake.nix
# Matches: version = "1.2.0";
sed -i "s/version = \".*\";/version = \"$VERSION\";/" "$FLAKE_FILE"

# Function to update hash for a system
update_hash() {
    local system=$1
    local os=$2
    local arch=$3
    
    echo "Processing $system ($os/$arch)..."
    
    # Extract hex hash from manifest
    local hex_hash
    hex_hash=$(echo "$MANIFEST" | jq -r ".passCliVersions.urls.\"$os\".\"$arch\".hash")
    
    if [ -z "$hex_hash" ] || [ "$hex_hash" = "null" ]; then
        echo "Error: Could not find hash for $system"
        exit 1
    fi
    
    # Convert to SRI hash using nix
    local sri_hash
    sri_hash=$(nix hash convert --hash-algo sha256 --to sri "$hex_hash")
    
    # Update flake.nix
    # This sed command finds the system block (e.g. "x86_64-linux = {") 
    # and replaces the first "hash = " line following it.
    # It uses a range /start/,/end/ but restricts the substitution to the first match in that range isn't trivial in one pass with standard sed.
    # Instead, we can use a block address.
    
    # We will use a temporary file to ensure we don't corrupt the original if something fails
    local temp_file
    temp_file=$(mktemp)
    
    # This sed command:
    # 1. Finds the line containing "$system = {"
    # 2. Starts a block
    # 3. Reads until "};"
    # 4. Inside that range, replaces the hash line.
    # Note: This assumes the hash is inside the block and unique enough or the first one.
    
    # A more robust sed for this specific structure:
    # /x86_64-linux = {/,/};/ { s|hash = ".*";|hash = "'"$sri_hash"'";| }
    
    sed "/$system = {/,/};/ s|hash = \".*\";|hash = \"$sri_hash\";|" "$FLAKE_FILE" > "$temp_file"
    mv "$temp_file" "$FLAKE_FILE"
}

# Update Hashes
update_hash "x86_64-linux" "linux" "x86_64"
update_hash "aarch64-linux" "linux" "aarch64"
update_hash "x86_64-darwin" "macos" "x86_64"
update_hash "aarch64-darwin" "macos" "aarch64"

echo "Done! Flake updated to version $VERSION"
