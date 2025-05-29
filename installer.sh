#!/bin/bash
# ----------------------------------------------------------------------
# installer.sh - Interactive installer for Ubuntu Server applications
# ----------------------------------------------------------------------
# Created: $(date +"%Y-%m-%d")
# Author: Cascade AI Assistant
# ----------------------------------------------------------------------
# Description:
#   This script provides an interactive menu for installing and managing
#   various applications on Ubuntu Server. It's designed to be easily
#   extensible with new applications.
# 
# Usage:
#   sudo ./installer.sh
#
# Requirements:
#   - Ubuntu Server
#   - Root/sudo privileges
# ----------------------------------------------------------------------

# Source helper functions
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/helpers.sh"

# Check if running as root
check_root

# Define application list
# Format: "app_name|Display Name|Description"
APPLICATIONS=(
    "telegram|Telegram Desktop|A cloud-based mobile and desktop messaging app"
    "streamrip|Streamrip|A command-line tool for downloading music from streaming services"
    "custom_scripts|Custom Scripts|Collection of useful utility scripts"
    # Add more applications here following the same format
)

# Display the main menu
show_main_menu() {
    clear
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}    Ubuntu Server Application Installer     ${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
    echo -e "Please select an option:"
    echo -e "  ${GREEN}1)${NC} Install Applications"
    echo -e "  ${GREEN}2)${NC} Uninstall Applications"
    echo -e "  ${GREEN}3)${NC} Update System"
    echo -e "  ${GREEN}4)${NC} Exit"
    echo ""
    echo -n "Enter your choice [1-4]: "
}

# Display the application menu for install/uninstall
show_app_menu() {
    local action=$1
    local title="Select Applications to $action"
    
    clear
    section_header "$title"
    echo ""
    
    local i=1
    for app_info in "${APPLICATIONS[@]}"; do
        IFS='|' read -r app_name display_name description <<< "$app_info"
        echo -e "  ${GREEN}$i)${NC} $display_name - $description"
        i=$((i+1))
    done
    
    echo -e "  ${GREEN}$i)${NC} Return to Main Menu"
    echo ""
    echo -n "Enter your choice [1-$i]: "
}

# Install selected application
install_application() {
    local app_name=$1
    
    # Check if the installation script exists
    local script_path="$SCRIPT_DIR/apps/${app_name}.sh"
    if [[ ! -f "$script_path" ]]; then
        log_message "ERROR" "Installation script for $app_name not found!"
        return 1
    fi
    
    # Make the script executable if it's not already
    chmod +x "$script_path"
    
    # Run the installation script
    "$script_path"
    
    # Pause after installation
    echo ""
    read -n 1 -s -r -p "Press any key to continue..."
}

# Uninstall selected application
uninstall_application() {
    local app_name=$1
    
    # Check if the installation script exists
    local script_path="$SCRIPT_DIR/apps/${app_name}.sh"
    if [[ ! -f "$script_path" ]]; then
        log_message "ERROR" "Uninstallation script for $app_name not found!"
        return 1
    fi
    
    # Make the script executable if it's not already
    chmod +x "$script_path"
    
    # Run the uninstallation script with 'uninstall' argument
    "$script_path" uninstall
    
    # Pause after uninstallation
    echo ""
    read -n 1 -s -r -p "Press any key to continue..."
}

# Update system packages
update_system() {
    section_header "System Update"
    
    log_message "INFO" "Updating package lists..."
    apt-get update -qq
    
    log_message "INFO" "Upgrading installed packages..."
    apt-get upgrade -y
    
    log_message "INFO" "System update completed"
    
    echo ""
    read -n 1 -s -r -p "Press any key to continue..."
}

# Main program loop
while true; do
    show_main_menu
    read -r choice
    
    case $choice in
        1) # Install Applications
            while true; do
                show_app_menu "Install"
                read -r app_choice
                
                # Check if the choice is valid
                if [[ $app_choice =~ ^[0-9]+$ ]] && [ "$app_choice" -gt 0 ] && [ "$app_choice" -le "${#APPLICATIONS[@]}" ]; then
                    # Get the app name from the array
                    IFS='|' read -r app_name _ _ <<< "${APPLICATIONS[$app_choice-1]}"
                    install_application "$app_name"
                elif [ "$app_choice" -eq $((${#APPLICATIONS[@]}+1)) ]; then
                    # Return to main menu
                    break
                else
                    log_message "ERROR" "Invalid option"
                    sleep 1
                fi
            done
            ;;
            
        2) # Uninstall Applications
            while true; do
                show_app_menu "Uninstall"
                read -r app_choice
                
                # Check if the choice is valid
                if [[ $app_choice =~ ^[0-9]+$ ]] && [ "$app_choice" -gt 0 ] && [ "$app_choice" -le "${#APPLICATIONS[@]}" ]; then
                    # Get the app name from the array
                    IFS='|' read -r app_name _ _ <<< "${APPLICATIONS[$app_choice-1]}"
                    uninstall_application "$app_name"
                elif [ "$app_choice" -eq $((${#APPLICATIONS[@]}+1)) ]; then
                    # Return to main menu
                    break
                else
                    log_message "ERROR" "Invalid option"
                    sleep 1
                fi
            done
            ;;
            
        3) # Update System
            update_system
            ;;
            
        4) # Exit
            echo "Thank you for using the Ubuntu Server Application Installer!"
            exit 0
            ;;
            
        *)
            log_message "ERROR" "Invalid option"
            sleep 1
            ;;
    esac
done
