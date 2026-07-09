#!/bin/bash
# Universal fix for ALL framework module copy phase errors
# Creates Modules/ModuleName.swiftmodule/Project directories for all frameworks

DERIVED_DATA_BASE="$HOME/Library/Developer/Xcode/DerivedData"
TELEGRAM_DD=$(find "$DERIVED_DATA_BASE" -maxdepth 1 -type d -name "Telegram-*" 2>/dev/null | head -1)

if [ -z "$TELEGRAM_DD" ]; then
    echo "No Telegram DerivedData found"
    exit 0
fi

echo "Found: $TELEGRAM_DD"

# Fix permissions first
chmod -R u+w "$TELEGRAM_DD/Build/Products/" 2>/dev/null

# Find ALL framework directories and create module structures
PRODUCTS_DIR="$TELEGRAM_DD/Build/Products"

find "$PRODUCTS_DIR" -type d -name "*.framework" 2>/dev/null | while read FW_PATH; do
    FW_NAME=$(basename "$FW_PATH" .framework)
    
    # Extract module name (remove "Framework" suffix if present)
    if [[ "$FW_NAME" == *Framework ]]; then
        MODULE_NAME="${FW_NAME%Framework}"
    else
        MODULE_NAME="$FW_NAME"
    fi
    
    # Create the module directories
    MODULE_DIR="$FW_PATH/Modules/${MODULE_NAME}.swiftmodule"
    PROJECT_DIR="$MODULE_DIR/Project"
    
    if [ ! -d "$MODULE_DIR" ]; then
        mkdir -p "$MODULE_DIR" 2>/dev/null && echo "Created: $MODULE_DIR"
    fi
    
    if [ ! -d "$PROJECT_DIR" ]; then
        mkdir -p "$PROJECT_DIR" 2>/dev/null && echo "Created: $PROJECT_DIR"
    fi
done

echo "Done! All framework module directories are ready."
