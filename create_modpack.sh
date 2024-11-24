#!/bin/bash

# Resolve the script's own directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

FTP_ARCHIVE="/srv/ftp/sigil-valheim.zip"

# Set the paths relative to the script's location
TARGET_ARCHIVE="$SCRIPT_DIR/sigil-valheim.zip"
PAYLOAD="$SCRIPT_DIR/lib"

# Generate a unique temporary directory
TEMP_DIR="$(mktemp -d /tmp/sigil-valheim.XXXXXX)"

# Parse arguments
UPLOAD_FTP=false
PASSWORD=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --ftp)
            UPLOAD_FTP=true
            shift
            ;;
        --password)
            PASSWORD="$2"
            shift 2
            ;;
        --password=*)
            PASSWORD="${1#*=}"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Check if payload directory exists
if [ ! -d "$PAYLOAD" ]; then
    echo "Error: Source directory $PAYLOAD does not exist."
    exit 1
fi

# Create the structure inside temporary directory
mkdir -p "$TEMP_DIR/mod_pack"

# Copy the contents of the source directory to the mod_pack directory
cp -r "$PAYLOAD/"* "$TEMP_DIR/mod_pack"

# Compress the directory into a .zip archive
cd "$TEMP_DIR" || exit 1

if [ -n "$PASSWORD" ]; then
    zip -r --password "$PASSWORD" "$TARGET_ARCHIVE" "mod_pack"
else
    zip -r "$TARGET_ARCHIVE" "mod_pack"
fi

# Clean up the temporary directory
rm -rf "$TEMP_DIR"

# Confirm the archive creation
if [ -f "$TARGET_ARCHIVE" ]; then
    echo "Archive created successfully: $TARGET_ARCHIVE"
else
    echo "Error: Failed to create archive."
    exit 1
fi

# Upload to FTP location if --ftp was specified
if [ "$UPLOAD_FTP" = true ]; then
    if [ ! -d "$(dirname "$FTP_ARCHIVE")" ]; then
        echo "Error: FTP directory does not exist: $(dirname "$FTP_ARCHIVE")"
        exit 1
    fi

    cp "$TARGET_ARCHIVE" "$FTP_ARCHIVE"

    if [ $? -eq 0 ]; then
        echo "Archive also uploaded to FTP location: $FTP_ARCHIVE"
    else
        echo "Error: Failed to upload archive to FTP location."
        exit 1
    fi
fi
