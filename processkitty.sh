#!/bin/bash

# Lauren Hall
# 02/23/2024
# Dependencies: ps, vmstat, iostat
# ASCII art provided by: https://asciiart.cc/view/12760

# Checks for --help argument or root privileges before proceeding
if [ "$#" -eq 1 ]; then
    if [ "$1" == "--help" ]; then
        # Help Section Here
        exit 0
    fi
elif [ "$(id -u)" -ne 0 ]; then
    echo "This script requires root privileges. Please run as root or use sudo." >&2
    exit 1
fi

# ASCII Art and Script Introduction
cat << "EOF"
                        .-.
          .-._    _.../   `,    _.-.
          |   `'-'    \     \_'`   |
          \            '.__,/ `\_.--,
           /                '._/     |
          /                    '.    /
         ;   _                  _'--;
      '--|- (_)       __       (_) -|--'
      .--|-          (__)          -|--.
       .-\-                        -/-.
      '   '.                      .'   `
  aac       '-._              _.-'          
                `""--....--""`
EOF

echo "Process Kitty"
echo "-------------------------------------"

# Prompt for system type, ensuring all necessary tools, and the rest of your functions here...

# Prompts the user to select their Unix system type or to exit the script
prompt_for_system_type() {
    local confirm_exit
    echo "Please identify your Unix system type:"
    echo "1. Debian/Ubuntu (Linux)"
    echo "2. CentOS/RHEL (Linux)"
    echo "3. Fedora (Linux)"
    echo "4. Other Unix-like systems"
    echo "5. Exit"
    read -p "Enter the number of your system type (or 5 to exit): " system_type_choice

    case $system_type_choice in
        1) SYSTEM_TYPE="Debian/Ubuntu";;
        2) SYSTEM_TYPE="CentOS/RHEL";;
        3) SYSTEM_TYPE="Fedora";;
        4) SYSTEM_TYPE="Other";;
        5) 
            read -p "Are you sure you want to exit? (y/N): " confirm_exit
            if [[ $confirm_exit =~ ^[Yy]$ ]]; then
                echo "Exiting script."
                exit 0
            else
                echo "Returning to main menu..."
                return
            fi
            ;;
        *) echo "Invalid selection. Exiting." >&2; exit 1;;
    esac
}

# A check for / Installation of missing tool function based on User selection of system type
ensure_tools_installed() {
    # Define necessary tools and their install commands for each system type
    declare -A tools=( ["accton"]="psacct/acct" ["vmstat"]="procps or procps-ng" ["iostat"]="sysstat" )

    for tool in "${!tools[@]}"; do
        if ! command -v $tool >/dev/null 2>&1; then
            echo "$tool is not available. It is usually part of the '${tools[$tool]}' package."

            # Install missing tool based on system type
            case $SYSTEM_TYPE in
                "Debian/Ubuntu")
                    echo "Attempting to install $tool for Debian/Ubuntu."
                    sudo apt-get update
                    case $tool in
                        "accton") sudo apt-get install -y acct ;;
                        "vmstat"|"iostat") sudo apt-get install -y procps sysstat ;;
                    esac
                    ;;
                "CentOS/RHEL"|"Fedora")
                    local pkg_manager="yum"
                    [[ $SYSTEM_TYPE == "Fedora" ]] && pkg_manager="dnf"
                    echo "Attempting to install $tool for CentOS/RHEL/Fedora using $pkg_manager."
                    case $tool in
                        "accton") sudo $pkg_manager install -y psacct ;;
                        "vmstat"|"iostat") sudo $pkg_manager install -y procps-ng sysstat ;;
                    esac
                    ;;
                "Other")
                    echo "Manual installation required for $tool on this system type. Please install the '${tools[$tool]}' package."
                    return 1
                    ;;
                *)
                    echo "Unsupported system type for $tool installation."
                    return 1
                    ;;
            esac
        else
            echo "$tool is already available."
        fi
    done

    echo "All necessary tools are checked and installed."
}

# A user display for key metric system with inclusion of tools including, free, vmstat, iostat, etc. this makes it easier to choose which process the user may want to view for comparison from menu options.
view_system_metrics() {
    echo "Displaying system-wide metrics..."
    echo "---------------------------------"

    # Memory and Swap Usage
    echo "Memory and Swap Usage:"
    free -h
    echo ""

    # CPU and I/O Statistics
    echo "CPU and I/O Statistics (Sampled over 1 second):"
    vmstat 1 2
    echo ""

    # Top Processes (Optional)
    echo "Top Processes (by CPU usage):"
    top -b -n 1 | head -20
    echo ""

    # Disk I/O (Optional, requires iostat)
    if command -v iostat >/dev/null 2>&1; then
        echo "Disk I/O Statistics:"
        iostat
    else
        echo "iostat command not found, skipping Disk I/O statistics."
    fi
}

list_processes() {
    # This function lists the first 20 running processes with their PID and command.
    echo "Currently running processes and their PIDs:"
    if ! ps -e -o pid,cmd | head -n 20; then
        echo "Failed to list processes." >&2
        exit 1
    fi
}


compare_two_processes() {
    # List all processes for the user to see
    list_processes

    echo "Enter the PID of the first process:"
    read pid1
    echo "Enter the PID of the second process:"
    read pid2

    echo "Which attribute do you want to compare?"
    echo "1. CPU Usage"
    echo "2. Memory Usage (RSS)"
    echo "3. Virtual Memory Size (VSZ)"
    echo "4. Process State"
    echo "5. Number of Threads (NLWP)"
    echo "6. Start Time"
    echo "7. CPU Time"
    echo "8. Priority"
    echo "9. Nice Value"
    echo "10. I/O Statistics (Read/Write)"
    read -p "Choose an option: " attribute_choice

    attribute="unsupported" # Default to unsupported

    # Attribute fetching logic
    case $attribute_choice in
        1) attribute="cpu_usage"; val1=$(ps -o %cpu= -p $pid1 | tr -d ' '); val2=$(ps -o %cpu= -p $pid2 | tr -d ' ') ;;
        2) attribute="rss"; val1=$(ps -o rss= -p $pid1 | tr -d ' '); val2=$(ps -o rss= -p $pid2 | tr -d ' ') ;;
        3) attribute="vsz"; val1=$(ps -o vsz= -p $pid1 | tr -d ' '); val2=$(ps -o vsz= -p $pid2 | tr -d ' ') ;;
        4) attribute="state"; val1=$(ps -o state= -p $pid1 | tr -d ' '); val2=$(ps -o state= -p $pid2 | tr -d ' ') ;;
        5) attribute="nlwp"; val1=$(ps -o nlwp= -p $pid1 | tr -d ' '); val2=$(ps -o nlwp= -p $pid2 | tr -d ' ') ;;
        6) attribute="start_time"; val1=$(ps -o lstart= -p $pid1); val2=$(ps -o lstart= -p $pid2) ;;
        7) attribute="cpu_time"; val1=$(ps -o cputime= -p $pid1 | tr -d ' '); val2=$(ps -o cputime= -p $pid2 | tr -d ' ') ;;
        8) attribute="priority"; val1=$(ps -o pri= -p $pid1 | tr -d ' '); val2=$(ps -o pri= -p $pid2 | tr -d ' ') ;;
        9) attribute="nice"; val1=$(ps -o nice= -p $pid1 | tr -d ' '); val2=$(ps -o nice= -p $pid2 | tr -d ' ') ;;
        # Skipping I/O statistics comparison due to complexity and potential requirement for root privileges
        *)
            echo "Invalid selection or unsupported attribute."
            return
            ;;
    esac

    # General comparison and output, handling both numeric and string values
    if [ -z "$val1" ] || [ -z "$val2" ]; then
        echo "Could not retrieve values for comparison."
    else
        echo "Process $pid1 $attribute: $val1"
        echo "Process $pid2 $attribute: $val2"
        if [[ "$attribute" == "start_time" || "$attribute" == "state" ]]; then
            echo "Comparison for attribute $attribute is not numeric. Please review the values above."
        else
            if (( $(echo "$val1 > $val2" | bc -l) )); then
                echo "Process $pid1 has a higher $attribute value."
            elif (( $(echo "$val1 < $val2" | bc -l) )); then
                echo "Process $pid2 has a higher $attribute value."
            else
                echo "Both processes have equal $attribute values."
            fi
        fi
    fi
}


# Main function/menu...
prompt_for_system_type
ensure_tools_installed

while true; do
    echo "-------------------------------------"
    echo "Process Accounting Management Script"
    echo "-------------------------------------"
    echo "1. Ensure all required tools are installed"
    echo "2. View System-wide Metrics"
    echo "3. Compare Two Processes by Attribute"
    echo "4. Exit"
    echo "-------------------------------------"
    read -p "Please choose an option: " main_choice

    case $main_choice in
        1) ensure_tools_installed ;;
        2) view_system_metrics ;;
        3) compare_two_processes ;;
        4) echo "Exiting..."; exit 0 ;;
        *) echo "Invalid option. Please choose again." >&2 ;;
    esac
    echo "Press Enter to return to the menu ..."
    read
done