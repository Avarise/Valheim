#!/bin/bash

# Define source and target directories
SOURCE_DIR="$HOME/Valheim/lib"
TEMP_DIR="/tmp/mod_pack_tmp"
TARGET_ARCHIVE="/srv/ftp/valheim/mod_pack.zip"

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Error: Source directory $SOURCE_DIR does not exist."
    exit 1
fi

# Ensure the target directory for the archive exists
if [ ! -d "$(dirname "$TARGET_ARCHIVE")" ]; then
    echo "Error: Target directory $(dirname "$TARGET_ARCHIVE") does not exist."
    exit 1
fi

# Create a temporary directory for constructing the archive
rm -rf "$TEMP_DIR"  # Clean up any leftover temporary directory
mkdir -p "$TEMP_DIR/mod_pack"

# Copy the contents of the source directory to the mod_pack directory
cp -r "$SOURCE_DIR/"* "$TEMP_DIR/mod_pack"

# Compress the directory into a .zip archive without including the full path
cd "$TEMP_DIR" || exit 1  # Change to temporary directory to avoid including full path
zip -r "$TARGET_ARCHIVE" "mod_pack"

# Clean up the temporary directory
rm -rf "$TEMP_DIR"

# Confirm the archive creation
if [ -f "$TARGET_ARCHIVE" ]; then
    echo "Archive created successfully: $TARGET_ARCHIVE"
else
    echo "Error: Failed to create archive."
    exit 1
fi
