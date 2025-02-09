#!/bin/bash

# Function to display available shells
show_available_shells() {
    echo "Available shells:"
    cat /etc/shells
}

# Check if a shell was provided as the first argument
if [ -z "$1" ]; then
    echo "Error: You must specify the desired shell as the first argument."
    show_available_shells
    exit 1
fi

# Set the desired shell from the first argument
NEW_SHELL="$1"

# Check if the specified shell is available
if ! grep -q "^$NEW_SHELL$" /etc/shells; then
    # Attempt to install zsh if requested
    if [ "$NEW_SHELL" == "/bin/zsh" ] || [ "$NEW_SHELL" == "/usr/bin/zsh" ]; then
        echo "zsh is not installed. Attempting to install zsh via apt..."
        
        # Check if the script is run with sudo
        if [ "$EUID" -ne 0 ]; then
            echo "This script needs sudo privileges to install zsh. Please rerun with sudo."
            exit 1
        fi

        apt update && apt install -y zsh

        # Verify if zsh is installed after the attempt
        if grep -q "^$NEW_SHELL$" /etc/shells; then
            echo "zsh successfully installed."
        else
            echo "Error: zsh installation failed or the shell is still not available."
            exit 1
        fi
    else
        echo "Error: The specified shell $NEW_SHELL is not available and automatic installation is only supported for zsh."
        show_available_shells
        exit 1
    fi
fi

# Display the current shell
CURRENT_SHELL=$(getent passwd "$USER" | cut -d: -f7)
echo "Current shell: $CURRENT_SHELL"
echo "New shell: $NEW_SHELL"

# Confirm with the user before changing the shell
chsh -s "$NEW_SHELL"

# If zsh is selected, copy the custom .zshrc from the repository
if [ "$NEW_SHELL" == "/bin/zsh" ] || [ "$NEW_SHELL" == "/usr/bin/zsh" ]; then
    ZSHRC_URL="https://raw.githubusercontent.com/hb9hil/change-shell/master/zshrc_custom"
    ZSHRC_PATH="$HOME/.zshrc"

    echo "Downloading custom .zshrc from $ZSHRC_URL..."
    curl -s -o "$ZSHRC_PATH" "$ZSHRC_URL"

    if [ $? -eq 0 ]; then
        echo ".zshrc successfully downloaded to $ZSHRC_PATH."
    else
        echo "Error: Failed to download .zshrc from $ZSHRC_URL."
    fi
fi

