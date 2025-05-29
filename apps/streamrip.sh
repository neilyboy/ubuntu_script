#!/bin/bash
# ----------------------------------------------------------------------
# streamrip.sh - Streamrip installer for Ubuntu Server
# ----------------------------------------------------------------------
# Created: $(date +"%Y-%m-%d")
# Author: Cascade AI Assistant
# ----------------------------------------------------------------------
# Description: 
#   This script installs streamrip, a command-line tool for downloading music 
#   from streaming services. (https://github.com/nathom/streamrip)
# ----------------------------------------------------------------------

# Source helper functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/helpers.sh"

# Installation method options
INSTALL_METHOD_PIP=1
INSTALL_METHOD_PIPX=2
INSTALL_METHOD_GIT=3

install_streamrip_pip() {
    section_header "Installing Streamrip via pip"
    
    # Check if pip is installed
    if ! command_exists pip3; then
        log_message "INFO" "Installing pip3..."
        install_package "python3-pip"
    fi
    
    # Install streamrip via pip
    log_message "INFO" "Installing streamrip via pip..."
    pip3 install streamrip
    
    # Verify installation
    if command_exists streamrip; then
        log_message "INFO" "Streamrip installed successfully via pip!"
        return 0
    else
        log_message "WARN" "Streamrip command not found in PATH. You may need to add ~/.local/bin to your PATH."
        log_message "INFO" "Trying to add ~/.local/bin to PATH..."
        
        # Add to PATH for current session
        export PATH="$HOME/.local/bin:$PATH"
        
        # Check if ~/.local/bin is in PATH
        if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
            log_message "INFO" "Adding ~/.local/bin to PATH in .bashrc..."
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
            log_message "INFO" "Please run 'source ~/.bashrc' or restart your terminal session."
        fi
        
        # Check again
        if [ -f "$HOME/.local/bin/streamrip" ]; then
            log_message "INFO" "Streamrip installed successfully at $HOME/.local/bin/streamrip!"
            return 0
        else
            log_message "ERROR" "Failed to install streamrip via pip"
            return 1
        fi
    fi
}

install_streamrip_pipx() {
    section_header "Installing Streamrip via Virtual Environment (System-wide)"
    
    # Install required packages for venv
    log_message "INFO" "Installing python3-venv..."
    install_package "python3-venv"
    install_package "python3-full"  # Needed for proper venv setup
    
    # Create a system-wide virtual environment for streamrip
    local venv_dir="/opt/streamrip_venv"
    log_message "INFO" "Creating virtual environment at $venv_dir..."
    
    # Remove existing venv if reinstalling
    if [ -d "$venv_dir" ]; then
        log_message "INFO" "Removing existing virtual environment..."
        rm -rf "$venv_dir"
    fi
    
    # Create new venv
    python3 -m venv "$venv_dir"
    
    # Install streamrip in the virtual environment
    log_message "INFO" "Installing streamrip in virtual environment..."
    "$venv_dir/bin/pip" install streamrip
    
    # Create symlinks to the executables in /usr/local/bin
    log_message "INFO" "Creating system-wide symlinks..."
    
    # Look for the executables in the virtual environment
    if [ -f "$venv_dir/bin/rip" ]; then
        ln -sf "$venv_dir/bin/rip" /usr/local/bin/rip
        log_message "INFO" "Created symlink for 'rip' command"
    elif [ -f "$venv_dir/bin/streamrip" ]; then
        ln -sf "$venv_dir/bin/streamrip" /usr/local/bin/streamrip
        log_message "INFO" "Created symlink for 'streamrip' command"
    else
        # If we can't find a direct executable, create a wrapper script
        log_message "INFO" "Creating wrapper script for streamrip..."
        cat > /usr/local/bin/rip << 'EOF'
#!/bin/bash
/opt/streamrip_venv/bin/python -m streamrip "$@"
EOF
        chmod +x /usr/local/bin/rip
        log_message "INFO" "Created wrapper script for 'rip' command"
    fi
    
    # Verify installation
    if command_exists rip || command_exists streamrip; then
        local cmd="rip"
        if command_exists rip; then
            cmd="rip"
        elif command_exists streamrip; then
            cmd="streamrip"
        fi
        log_message "INFO" "Streamrip installed successfully and available system-wide!"
        log_message "INFO" "The command to use streamrip is '$cmd'"
        return 0
    else
        log_message "ERROR" "Failed to install streamrip with system-wide access"
        return 1
    fi
}

install_streamrip_git() {
    section_header "Installing Streamrip from GitHub source"
    
    # Install dependencies
    log_message "INFO" "Installing git and python dependencies..."
    install_package "git"
    install_package "python3-pip"
    
    # Create temp directory
    local temp_dir=$(mktemp -d)
    
    # Clone the repository
    log_message "INFO" "Cloning streamrip repository..."
    git clone https://github.com/nathom/streamrip.git "$temp_dir"
    
    # Install from source
    log_message "INFO" "Installing streamrip from source..."
    cd "$temp_dir"
    pip3 install .
    
    # Cleanup
    rm -rf "$temp_dir"
    
    # Verify installation
    if command_exists streamrip || [ -f "$HOME/.local/bin/streamrip" ]; then
        log_message "INFO" "Streamrip installed successfully from source!"
        return 0
    else
        log_message "ERROR" "Failed to install streamrip from source"
        return 1
    fi
}

install_ffmpeg() {
    section_header "Installing FFmpeg (Required Dependency)"
    
    # Check if FFmpeg is already installed
    if command_exists ffmpeg; then
        log_message "INFO" "FFmpeg is already installed"
        return 0
    fi
    
    # Install FFmpeg
    log_message "INFO" "Installing FFmpeg..."
    install_package "ffmpeg"
    
    # Verify installation
    if command_exists ffmpeg; then
        log_message "INFO" "FFmpeg installed successfully!"
        return 0
    else
        log_message "ERROR" "Failed to install FFmpeg"
        return 1
    fi
}

install_streamrip() {
    section_header "Installing Streamrip"
    
    # Check if streamrip is already installed (check for both 'streamrip' and 'rip' commands)
    if command_exists streamrip || command_exists rip || [ -f "$HOME/.local/bin/streamrip" ] || [ -f "$HOME/.local/bin/rip" ] || [ -f "/root/.local/bin/rip" ]; then
        log_message "INFO" "Streamrip is already installed"
        if confirm "Would you like to reinstall Streamrip?"; then
            log_message "INFO" "Proceeding with reinstallation..."
        else
            log_message "INFO" "Skipping Streamrip installation"
            return 0
        fi
    fi
    
    # Install FFmpeg (required dependency)
    install_ffmpeg
    
    # Install other dependencies
    log_message "INFO" "Installing required dependencies..."
    local dependencies=(
        "python3"
        "python3-dev"
        "build-essential"
    )
    install_packages "${dependencies[@]}"
    
    # Ask for installation method
    echo ""
    echo "Please select an installation method:"
    echo -e "  ${GREEN}1)${NC} Install via pip (simplest method)"
    echo -e "  ${GREEN}2)${NC} Install via pipx (isolated environment, recommended)"
    echo -e "  ${GREEN}3)${NC} Install from GitHub source"
    echo ""
    echo -n "Enter your choice [1-3]: "
    read -r method_choice
    
    case $method_choice in
        1)
            install_streamrip_pip
            ;;
        2)
            install_streamrip_pipx
            ;;
        3)
            install_streamrip_git
            ;;
        *)
            log_message "ERROR" "Invalid option, defaulting to pip installation"
            install_streamrip_pip
            ;;
    esac
    
    # Show usage instructions
    if command_exists streamrip || command_exists rip || [ -f "$HOME/.local/bin/streamrip" ] || [ -f "$HOME/.local/bin/rip" ] || [ -f "/root/.local/bin/rip" ]; then
        echo ""
        log_message "INFO" "Streamrip has been installed successfully!"
        echo ""
        echo -e "${BLUE}Basic Streamrip Usage:${NC}"
        
        # Determine which command to use
        local cmd="streamrip"
        if command_exists rip || [ -f "$HOME/.local/bin/rip" ] || [ -f "/root/.local/bin/rip" ]; then
            cmd="rip"
        fi
        
        echo -e "  ${GREEN}$cmd config${NC} - Configure streamrip with your streaming service credentials"
        echo -e "  ${GREEN}$cmd url <streaming_url>${NC} - Download music from a streaming URL"
        echo -e "  ${GREEN}$cmd search <query>${NC} - Search for music"
        echo -e "  ${GREEN}$cmd -h${NC} - Display help information"
        echo ""
        log_message "INFO" "For more information, visit: https://github.com/nathom/streamrip"
    fi
    
    return 0
}

# Function to uninstall streamrip
uninstall_streamrip() {
    section_header "Uninstalling Streamrip"
    
    # Check if streamrip is installed via pip/pipx (checking both 'streamrip' and 'rip')
    if command_exists streamrip || command_exists rip || [ -f "$HOME/.local/bin/streamrip" ] || [ -f "$HOME/.local/bin/rip" ] || [ -f "/root/.local/bin/rip" ]; then
        if command_exists pipx && pipx list | grep -q streamrip; then
            log_message "INFO" "Uninstalling streamrip via pipx..."
            pipx uninstall streamrip
        else
            log_message "INFO" "Uninstalling streamrip via pip..."
            pip3 uninstall -y streamrip
        fi
        
        # Verify uninstallation
        if ! command_exists streamrip && ! command_exists rip && [ ! -f "$HOME/.local/bin/streamrip" ] && [ ! -f "$HOME/.local/bin/rip" ] && [ ! -f "/root/.local/bin/rip" ]; then
            log_message "INFO" "Streamrip uninstalled successfully!"
        else
            log_message "ERROR" "Failed to uninstall streamrip"
            return 1
        fi
    else
        log_message "INFO" "Streamrip is not installed"
    fi
    
    return 0
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Install or uninstall based on argument
    if [[ "$1" == "uninstall" ]]; then
        uninstall_streamrip
    else
        install_streamrip
    fi
fi
