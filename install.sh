#!/bin/bash

set -e

echo "Installing PDF Decrypt Action..."

# Check if macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "This script is designed for macOS only."
    exit 1
fi

# Check if qpdf is installed
if ! command -v qpdf &> /dev/null; then
    echo "qpdf is required but not installed."
    echo "Please install it with: brew install qpdf"
    exit 1
fi

# Create directories
SCRIPT_DIR="$HOME/Library/Scripts"
SERVICE_DIR="$HOME/Library/Services"
mkdir -p "$SCRIPT_DIR"
mkdir -p "$SERVICE_DIR"

# Download the main script
echo "Downloading main script..."
curl -fsSL https://raw.githubusercontent.com/bukshanekom/pdf-decrypt-action/main/decrypt-pdf-action.sh -o "$SCRIPT_DIR/decrypt-pdf-action.sh"
chmod +x "$SCRIPT_DIR/decrypt-pdf-action.sh"

# Create Automator service directory
mkdir -p "$SERVICE_DIR/PDF Decrypt Action.workflow/Contents"

# Create Automator service plist
cat > "$SERVICE_DIR/PDF Decrypt Action.workflow/Contents/Info.plist" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>NSServices</key>
    <array>
        <dict>
            <key>NSMenuItem</key>
            <dict>
                <key>default</key>
                <string>PDF Decrypt Action</string>
            </dict>
            <key>NSMessage</key>
            <string>runWorkflowAsService</string>
            <key>NSRequiredContext</key>
            <dict>
                <key>NSApplicationIdentifier</key>
                <string>com.apple.finder</string>
            </dict>
            <key>NSSendFileTypes</key>
            <array>
                <string>com.adobe.pdf</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
EOF

# Create example password file if it doesn't exist
if [ ! -f "$HOME/.decrypt-pdf-action" ]; then
    echo "Creating example password file..."
    echo "# Add your passwords here, one per line" > "$HOME/.decrypt-pdf-action"
    echo "# Example:" >> "$HOME/.decrypt-pdf-action"
    echo "# password123" >> "$HOME/.decrypt-pdf-action"
    echo "# your_id_number" >> "$HOME/.decrypt-pdf-action"
    echo ""
    echo "Please edit ~/.decrypt-pdf-action and add your passwords"
fi

echo "Installation complete!"
echo ""
echo "Next steps:"
echo "1. Edit ~/.decrypt-pdf-action and add your passwords (one per line)"
echo "2. Right-click any PDF in Finder → Services → 'PDF Decrypt Action'"
echo ""
echo "Logs are saved to: ~/Library/Logs/decrypt-pdf-action.log"