#!/bin/bash

# Lauren Hall
# 02/23/2024
# Dependencies: ps, vmstat, iostat
# ASCII art provided by: https://asciiart.cc/view/12760

main() {
    parse_arguments "$@"
    check_root_privileges
    display_ascii_art
    display_intro
    handle_user_interaction
}

display_ascii_art() {
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
}

display_intro() {
    printf "Process Kitty\n"
    printf "-------------------------------------\n"
}

parse_arguments() {
    while getopts ":hm:tp:" opt; do
        case ${opt} in
            h ) show_advanced_help; exit 0 ;;
            m ) memory_limit="$OPTARG" ;;
            t ) track_parentage=true ;;
            p ) specific_pid="$OPTARG" ;;
            \? ) printf "Invalid Option: -$OPTARG" 1>&2; exit 1 ;;
        esac
    done
}

show_advanced_help() {
    cat << EOF
Process Kitty - Advanced Help Section

Usage:
  ./script.sh [options]

Options:
  --help, -h                          Show basic help message and exit.
  -m <memory_limit_in_KB>, --memory   Filter processes by memory usage (in KB).
  -t, --track                         Track process parentage.
  -p <PID>, --pid                     Specify a PID for detailed analysis.
  --list-all                          List all processes.
  --filter-by-user <username>         Filter processes by the specified user.
  --filter-by-state <state>           Filter processes by their state (e.g., running, sleeping).

Examples:
  ./script.sh -m 1024                 List processes exceeding 1024 KB of memory usage.
  ./script.sh --track -p 1234         Track the parentage of process with PID 1234.
  ./script.sh --list-all              List all processes on the system.
  ./script.sh --filter-by-user root   List processes owned by the root user.
  ./script.sh --filter-by-state R     List processes in the running state.

Note: Some options might require root privileges to execute properly.

EOF
}

check_root_privileges() {
    if [ "$(id -u)" -ne 0 ]; then
        printf "This script requires root privileges. Please run as root.\n" >&2
        exit 1
    fi
}

handle_user_interaction() {
    while true; do
        echo  "-------------------------------------"
        echo  "Process Accounting Management Script"
        echo  "-------------------------------------"
        echo  "0. Exit"
        echo  "1. Ensure all required tools are installed"
        echo  "2. View System-wide Metrics"
        echo  "3. Compare Two Processes by Attribute"
        echo  "4. List Processes Exceeding Memory Usage"
        echo  "5. Track Process Parentage"
        echo  "6. List All Processes"
        echo  "-------------------------------------"
        read -p "Please choose an option: " main_choice

        case $main_choice in
            0) echo "Exiting..."; exit 0 ;;
            1) ensure_tools_installed ;;
            2) view_system_metrics ;;
            3) compare_two_processes ;;
            4) 
                read -p "Enter memory usage limit in K: " memory_limit
                list_processes_filtered_by_memory "$memory_limit"
                ;;
            5) 
                read -p "Enter PID to track parentage: " pid
                track_process_parentage "$pid"
                ;;
            6) list_all_processes ;;
            *) echo "Invalid option. Please choose again.\n" >&2 ;;
        esac
        echo "Press Enter to return to the menu ..."
        read
    done
}

ensure_tools_installed() {
    local tools=("ps" "vmstat" "iostat")
    for tool in "${tools[@]}"; do
        if ! command -v $tool &> /dev/null; then
            printf "$tool is required but not installed. Please install it before running this script.\n" >&2
            exit 1
        fi
    done
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

# Example implementation of list_processes_filtered_by_memory
list_processes_filtered_by_memory() {
    if [ -n "$memory_limit" ]; then
        echo "Listing processes exceeding $memory_limit KB of memory usage:"
        ps -eo pid,vsz,comm | awk -v limit=$memory_limit '$2 > limit {print}'
    fi
}

track_process_parentage() {
    local pid=$1
    echo "Tracking parentage for PID: $pid"
    while [ $pid -ne 0 ]; do
        echo "PID: $pid"
        pid=$(ps -o ppid= -p $pid)
    done
}



list_all_processes() {
    ps aux
}

main "$@"
