#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
CONTINUE_DIR=~/.continue
CONFIG_JSON=$CONTINUE_DIR/config.json
CONFIG_TS=$CONTINUE_DIR/config.ts
CONFIG_YAML=$CONTINUE_DIR/config.yaml

# Check if CBORG_API_KEY is set
API_KEY_SET=false
if [ -n "$CBORG_API_KEY" ]; then
    API_KEY_SET=true
fi

# Create ~/.continue directory if it doesn't exist
mkdir -p $CONTINUE_DIR

# Function to backup a file if it exists
backup_file() {
    local file=$1
    if [ -f "$file" ]; then
        mv "$file" "${file}.ori"
        echo "Backed up $file to ${file}.ori"
    fi
}

# Display installation options
echo "Install CBorg Integration with VS Code Continue"
echo "Please select an installation type:"
echo "1) Manual"
if $API_KEY_SET; then
    echo "2) Standard (Recommended)"
    echo "3) Proxy (Advanced)"
else
    echo "2) Standard (Recommended) - Not Available - no \$CBORG_API_KEY found in user environment"
    echo "3) Proxy (Advanced) - Not Available - no \$CBORG_API_KEY found in user environment"
fi

# Get user selection
read -p "Enter your choice (1-3): " choice

# Process based on selection
case $choice in
    1)
        echo "Manual installation selected."
        read -p "Please enter your CBorg API key: " manual_api_key
        
        # Backup existing config files
        backup_file "$CONFIG_JSON"
        backup_file "$CONFIG_YAML"
        
        # Copy standard config and replace API key
        cp "$SCRIPT_DIR/standard-config.json" "$CONFIG_JSON"
        
        # macOS-compatible sed command (works on Linux too)
        sed -e "s|\${CBORG_API_KEY}|$manual_api_key|g" "$SCRIPT_DIR/standard-config.json" > "$CONFIG_JSON"
        
        echo "Manual installation completed."
        ;;
    2)
        if $API_KEY_SET; then
            echo "Standard installation selected."
            
            # Backup existing config files
            backup_file "$CONFIG_JSON"
            backup_file "$CONFIG_TS"
            backup_file "$CONFIG_YAML"
            
            # Create symlinks
            ln -sf "$SCRIPT_DIR/standard-config.json" "$CONFIG_JSON"
            ln -sf "$SCRIPT_DIR/config.ts" "$CONFIG_TS"
            
            echo "Standard installation completed."
        else
            echo "Standard installation not available without CBORG_API_KEY environment variable."
            exit 1
        fi
        ;;
    3)
        if $API_KEY_SET; then
            echo "Proxy installation selected."
            
            # Backup existing config files
            backup_file "$CONFIG_JSON"
            backup_file "$CONFIG_YAML"
            
            # Create symlink
            ln -sf "$SCRIPT_DIR/cborg-proxy-config.json" "$CONFIG_JSON"
            
            echo "Proxy installation completed."
        else
            echo "Proxy installation not available without CBORG_API_KEY environment variable."
            exit 1
        fi
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

echo "Installation completed successfully."