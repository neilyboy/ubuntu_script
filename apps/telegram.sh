#!/bin/bash
# ----------------------------------------------------------------------
# telegram.sh - Telegram Desktop installer for Ubuntu Server
# ----------------------------------------------------------------------
# Created: $(date +"%Y-%m-%d")
# Author: Cascade AI Assistant
# ----------------------------------------------------------------------

# Source helper functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/helpers.sh"

# Installation method options
INSTALL_METHOD_SNAP=1
INSTALL_METHOD_DIRECT=2

install_telegram_snap() {
    section_header "Installing Telegram Desktop via Snap"
    
    # Check if snap is installed
    if ! command_exists snap; then
        log_message "INFO" "Installing snap package manager..."
        install_package "snapd"
        
        # Ensure snap is properly initialized
        systemctl enable --now snapd.socket
        
        # Create symbolic link for classic snap support
        if [ ! -e /snap ]; then
            ln -s /var/lib/snapd/snap /snap
        fi
    fi
    
    # Install Telegram Desktop from snap
    log_message "INFO" "Installing Telegram Desktop from Snap store..."
    snap install telegram-desktop
    
    # Verify installation
    if snap list | grep -q telegram-desktop; then
        log_message "INFO" "Telegram Desktop installed successfully via Snap!"
        return 0
    else
        log_message "ERROR" "Failed to install Telegram Desktop via Snap"
        return 1
    fi
}

install_telegram_direct() {
    section_header "Installing Telegram Desktop from direct download"
    
    # Create installation directory
    local install_dir="/opt/telegram"
    if [ ! -d "$install_dir" ]; then
        mkdir -p "$install_dir"
    fi
    
    # Get latest Telegram desktop
    log_message "INFO" "Downloading Telegram Desktop..."
    local temp_dir=$(mktemp -d)
    local telegram_url="https://telegram.org/dl/desktop/linux"
    
    wget -O "$temp_dir/telegram.tar.xz" "$telegram_url" || {
        log_message "ERROR" "Failed to download Telegram Desktop"
        rm -rf "$temp_dir"
        return 1
    }
    
    # Extract the archive
    log_message "INFO" "Extracting Telegram Desktop..."
    tar -xJf "$temp_dir/telegram.tar.xz" -C "$install_dir" --strip-components=1 || {
        log_message "ERROR" "Failed to extract Telegram Desktop"
        rm -rf "$temp_dir"
        return 1
    }
    
    # Cleanup temp directory
    rm -rf "$temp_dir"
    
    # Create symbolic links
    ln -sf "$install_dir/Telegram" /usr/local/bin/telegram-desktop
    
    # Create desktop shortcut
    create_desktop_shortcut "Telegram" "/usr/local/bin/telegram-desktop" "$install_dir/telegram.svg"
    
    # Verify installation
    if [ -f "$install_dir/Telegram" ]; then
        log_message "INFO" "Telegram Desktop installed successfully via direct download!"
        return 0
    else
        log_message "ERROR" "Failed to install Telegram Desktop via direct download"
        return 1
    fi
}

install_telegram() {
    section_header "Installing Telegram Desktop"
    
    # Check if Telegram is already installed
    if command_exists telegram-desktop || [ -f "/usr/local/bin/telegram-desktop" ] || snap list 2>/dev/null | grep -q telegram-desktop; then
        log_message "INFO" "Telegram Desktop is already installed"
        if confirm "Would you like to reinstall Telegram Desktop?"; then
            log_message "INFO" "Proceeding with reinstallation..."
        else
            log_message "INFO" "Skipping Telegram Desktop installation"
            return 0
        fi
    fi
    
    # Install dependencies
    log_message "INFO" "Installing required dependencies..."
    local dependencies=(
        "wget"
        "tar"
        "xz-utils"
    )
    install_packages "${dependencies[@]}"
    
    # Ask for installation method
    echo ""
    echo "Please select an installation method:"
    echo -e "  ${GREEN}1)${NC} Install via Snap (recommended for Ubuntu)"
    echo -e "  ${GREEN}2)${NC} Install via direct download from Telegram website"
    echo ""
    echo -n "Enter your choice [1-2]: "
    read -r method_choice
    
    case $method_choice in
        1)
            install_telegram_snap
            ;;
        2)
            install_telegram_direct
            ;;
        *)
            log_message "ERROR" "Invalid option, defaulting to Snap installation"
            install_telegram_snap
            ;;
    esac
    
    # For headless server environments, we need to ensure X11 is available
    log_message "INFO" "Checking for X11 requirements..."
    local x11_deps=(
        "xorg"
        "xserver-xorg"
        "x11-apps"
        "xvfb"  # Virtual framebuffer X server
    )
    
    if confirm "Install X11 packages for GUI support?"; then
        install_packages "${x11_deps[@]}"
        log_message "INFO" "X11 packages installed"
    fi
    
    # Provide instructions for running on a headless server
    log_message "INFO" "To run Telegram on a headless server, you can use: xvfb-run telegram-desktop"
    
    return 0
}

# Function to uninstall Telegram
uninstall_telegram() {
    section_header "Uninstalling Telegram Desktop"
    
    # Check different installation methods
    local uninstalled=false
    
    # Check if installed via snap
    if snap list 2>/dev/null | grep -q telegram-desktop; then
        log_message "INFO" "Uninstalling Telegram Desktop from Snap..."
        snap remove telegram-desktop
        uninstalled=true
    fi
    
    # Check if installed via direct download
    if [ -f "/usr/local/bin/telegram-desktop" ] || [ -d "/opt/telegram" ]; then
        log_message "INFO" "Uninstalling Telegram Desktop from direct installation..."
        rm -f /usr/local/bin/telegram-desktop
        rm -rf /opt/telegram
        rm -f /usr/share/applications/Telegram.desktop
        uninstalled=true
    fi
    
    # Check if installed via apt
    if command_exists telegram-desktop && ! $uninstalled; then
        log_message "INFO" "Uninstalling Telegram Desktop from apt..."
        apt-get remove -y telegram-desktop
        
        # Remove the repository if it exists
        if [ -f /etc/apt/sources.list.d/telegram.list ]; then
            log_message "INFO" "Removing Telegram repository..."
            rm /etc/apt/sources.list.d/telegram.list
            
            # Remove the signing key
            if [ -f /usr/share/keyrings/telegram.gpg ]; then
                rm /usr/share/keyrings/telegram.gpg
            fi
            
            # Update package list after removing repository
            update_packages
        fi
        
        uninstalled=true
    fi
    
    if $uninstalled; then
        log_message "INFO" "Telegram Desktop uninstalled successfully"
    else
        log_message "INFO" "Telegram Desktop was not found to be installed"
    fi
    
    return 0
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Check if script is run as root
    check_root
    
    # Install or uninstall based on argument
    if [[ "$1" == "uninstall" ]]; then
        uninstall_telegram
    else
        install_telegram
    fi
fi
