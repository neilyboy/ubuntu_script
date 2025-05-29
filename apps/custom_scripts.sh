#!/bin/bash
# ----------------------------------------------------------------------
# custom_scripts.sh - Custom scripts installer for Ubuntu Server
# ----------------------------------------------------------------------
# Created: $(date +"%Y-%m-%d")
# Author: Cascade AI Assistant
# ----------------------------------------------------------------------
# Description: 
#   This script installs custom utility scripts to make them available
#   system-wide.
# ----------------------------------------------------------------------

# Source helper functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../utils/helpers.sh"

# Define available custom scripts
# Format: "script_name|Description|Dependencies"
CUSTOM_SCRIPTS=(
    "zipem|Quick archive creator for multiple directories|zip tar gzip"
    "uploadem|File uploader for Gofile and BuzzHeavier|curl jq"
    # Add more scripts here as needed
)

# Install a single script
install_script() {
    local script_name=$1
    local description=$2
    local dependencies=$3
    
    section_header "Installing $script_name"
    
    # Install dependencies if specified
    if [ -n "$dependencies" ]; then
        log_message "INFO" "Installing dependencies for $script_name..."
        for dep in $dependencies; do
            install_package "$dep"
        done
    fi
    
    # Copy script to /usr/local/bin to make it available system-wide
    local source_path="$SCRIPT_DIR/../custom_scripts/$script_name"
    local target_path="/usr/local/bin/$script_name"
    
    if [ ! -f "$source_path" ]; then
        log_message "ERROR" "Script file not found: $source_path"
        return 1
    fi
    
    log_message "INFO" "Installing $script_name to $target_path..."
    cp "$source_path" "$target_path"
    chmod +x "$target_path"
    
    log_message "INFO" "$script_name installed successfully"
    
    # Show usage instructions
    echo ""
    echo -e "${BLUE}Basic Usage:${NC}"
    case "$script_name" in
        "zipem")
            echo -e "  ${GREEN}zipem${NC} - Create zero-compression archives for all directories"
            echo -e "  ${GREEN}zipem --compress${NC} - Create compressed archives"
            echo -e "  ${GREEN}zipem --format tar${NC} - Create tar archives instead of zip"
            echo -e "  ${GREEN}zipem --help${NC} - Show detailed help"
            ;;
        "uploadem")
            echo -e "  ${GREEN}uploadem file.zip${NC} - Upload a single file"
            echo -e "  ${GREEN}uploadem file1.mp4 file2.mp4${NC} - Upload multiple files"
            echo -e "  ${GREEN}uploadem *.zip${NC} - Upload all ZIP files in the current directory"
            echo -e "  ${GREEN}uploadem --help${NC} - Show detailed help"
            ;;
        # Add other scripts' usage info here
        *)
            echo -e "  ${GREEN}$script_name --help${NC} - Show detailed help"
            ;;
    esac
    
    return 0
}

# Uninstall a single script
uninstall_script() {
    local script_name=$1
    
    section_header "Uninstalling $script_name"
    
    local target_path="/usr/local/bin/$script_name"
    
    if [ -f "$target_path" ]; then
        log_message "INFO" "Removing $script_name..."
        rm -f "$target_path"
        log_message "INFO" "$script_name uninstalled successfully"
    else
        log_message "INFO" "$script_name is not installed"
    fi
    
    return 0
}

# Install all custom scripts
install_custom_scripts() {
    section_header "Custom Scripts Installation"
    
    echo "The following custom scripts are available:"
    echo ""
    
    local i=1
    for script_info in "${CUSTOM_SCRIPTS[@]}"; do
        IFS='|' read -r script_name description dependencies <<< "$script_info"
        echo -e "  ${GREEN}$i)${NC} $script_name - $description"
        i=$((i+1))
    done
    
    echo -e "  ${GREEN}$i)${NC} Install all scripts"
    echo -e "  ${GREEN}$((i+1))${NC} Return to previous menu"
    echo ""
    echo -n "Enter your choice [1-$((i+1))]: "
    read -r choice
    
    if [[ $choice =~ ^[0-9]+$ ]]; then
        if [ "$choice" -eq "$i" ]; then
            # Install all scripts
            for script_info in "${CUSTOM_SCRIPTS[@]}"; do
                IFS='|' read -r script_name description dependencies <<< "$script_info"
                install_script "$script_name" "$description" "$dependencies"
            done
        elif [ "$choice" -lt "$i" ] && [ "$choice" -gt 0 ]; then
            # Install selected script
            IFS='|' read -r script_name description dependencies <<< "${CUSTOM_SCRIPTS[$choice-1]}"
            install_script "$script_name" "$description" "$dependencies"
        elif [ "$choice" -eq "$((i+1))" ]; then
            # Return to previous menu
            return 0
        else
            log_message "ERROR" "Invalid choice"
            return 1
        fi
    else
        log_message "ERROR" "Invalid input"
        return 1
    fi
    
    # Pause after installation
    echo ""
    read -n 1 -s -r -p "Press any key to continue..."
    
    return 0
}

# Uninstall custom scripts
uninstall_custom_scripts() {
    section_header "Custom Scripts Uninstallation"
    
    echo "The following custom scripts are available to uninstall:"
    echo ""
    
    local i=1
    for script_info in "${CUSTOM_SCRIPTS[@]}"; do
        IFS='|' read -r script_name _ _ <<< "$script_info"
        echo -e "  ${GREEN}$i)${NC} $script_name"
        i=$((i+1))
    done
    
    echo -e "  ${GREEN}$i)${NC} Uninstall all scripts"
    echo -e "  ${GREEN}$((i+1))${NC} Return to previous menu"
    echo ""
    echo -n "Enter your choice [1-$((i+1))]: "
    read -r choice
    
    if [[ $choice =~ ^[0-9]+$ ]]; then
        if [ "$choice" -eq "$i" ]; then
            # Uninstall all scripts
            for script_info in "${CUSTOM_SCRIPTS[@]}"; do
                IFS='|' read -r script_name _ _ <<< "$script_info"
                uninstall_script "$script_name"
            done
        elif [ "$choice" -lt "$i" ] && [ "$choice" -gt 0 ]; then
            # Uninstall selected script
            IFS='|' read -r script_name _ _ <<< "${CUSTOM_SCRIPTS[$choice-1]}"
            uninstall_script "$script_name"
        elif [ "$choice" -eq "$((i+1))" ]; then
            # Return to previous menu
            return 0
        else
            log_message "ERROR" "Invalid choice"
            return 1
        fi
    else
        log_message "ERROR" "Invalid input"
        return 1
    fi
    
    # Pause after uninstallation
    echo ""
    read -n 1 -s -r -p "Press any key to continue..."
    
    return 0
}

# Main execution
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Check if script is run as root
    check_root
    
    # Install or uninstall based on argument
    if [[ "$1" == "uninstall" ]]; then
        uninstall_custom_scripts
    else
        install_custom_scripts
    fi
fi
