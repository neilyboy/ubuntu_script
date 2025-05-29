#!/bin/bash
# ----------------------------------------------------------------------
# helpers.sh - Common utility functions for the installer scripts
# ----------------------------------------------------------------------
# Created: $(date +"%Y-%m-%d")
# Author: Cascade AI Assistant
# ----------------------------------------------------------------------

# Text formatting
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log a message with a timestamp
log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    case $level in
        "INFO")
            echo -e "${GREEN}[INFO]${NC} $timestamp - $message"
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${NC} $timestamp - $message"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $timestamp - $message"
            ;;
        *)
            echo -e "$timestamp - $message"
            ;;
    esac
}

# Display a section header
section_header() {
    local title=$1
    echo -e "\n${BLUE}==== $title ====${NC}"
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Ask for user confirmation
confirm() {
    local prompt=$1
    local default=${2:-"y"}
    
    if [[ $default == "y" ]]; then
        prompt="$prompt [Y/n] "
    else
        prompt="$prompt [y/N] "
    fi
    
    read -r -p "$prompt" response
    response=${response,,} # Convert to lowercase
    
    if [[ -z $response ]]; then
        response=$default
    fi
    
    [[ $response =~ ^(yes|y)$ ]]
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_message "ERROR" "This script must be run as root or with sudo privileges"
        exit 1
    fi
}

# Update package lists
update_packages() {
    section_header "Updating Package Lists"
    log_message "INFO" "Updating package lists..."
    apt-get update -qq || {
        log_message "ERROR" "Failed to update package lists"
        return 1
    }
    log_message "INFO" "Package lists updated successfully"
}

# Install a package if it's not already installed
install_package() {
    local package=$1
    
    if dpkg -l | grep -q "^ii  $package "; then
        log_message "INFO" "Package '$package' is already installed"
        return 0
    fi
    
    log_message "INFO" "Installing package '$package'..."
    apt-get install -y "$package" > /dev/null || {
        log_message "ERROR" "Failed to install package '$package'"
        return 1
    }
    
    log_message "INFO" "Package '$package' installed successfully"
}

# Install multiple packages
install_packages() {
    local packages=("$@")
    
    for package in "${packages[@]}"; do
        install_package "$package"
    done
}

# Create a desktop shortcut
create_desktop_shortcut() {
    local name=$1
    local exec_path=$2
    local icon_path=$3
    local desktop_file="/usr/share/applications/$name.desktop"
    
    cat > "$desktop_file" << EOF
[Desktop Entry]
Name=$name
Exec=$exec_path
Icon=$icon_path
Type=Application
Categories=Network;InstantMessaging;
EOF

    log_message "INFO" "Desktop shortcut created for $name"
}
