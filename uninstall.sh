#!/bin/bash

echo "Uninstalling PDF Decrypt Action..."

# Remove script
if [ -f "$HOME/Library/Scripts/decrypt-pdf-action.sh" ]; then
    rm "$HOME/Library/Scripts/decrypt-pdf-action.sh"
    echo "Removed main script"
fi

# Remove service
if [ -d "$HOME/Library/Services/PDF Decrypt Action.workflow" ]; then
    rm -rf "$HOME/Library/Services/PDF Decrypt Action.workflow"
    echo "Removed Finder service"
fi

# Ask about password file
if [ -f "$HOME/.decrypt-pdf-action" ]; then
    echo ""
    read -p "Remove password file (~/.decrypt-pdf-action)? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm "$HOME/.decrypt-pdf-action"
        echo "Removed password file"
    else
        echo "Password file kept at ~/.decrypt-pdf-action"
    fi
fi

# Ask about log file
if [ -f "$HOME/Library/Logs/decrypt-pdf-action.log" ]; then
    echo ""
    read -p "Remove log file? [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm "$HOME/Library/Logs/decrypt-pdf-action.log"
        echo "Removed log file"
    else
        echo "Log file kept at ~/Library/Logs/decrypt-pdf-action.log"
    fi
fi

echo ""
echo "Uninstallation complete!"