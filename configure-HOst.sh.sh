#!/bin/bash

# Function to log messages if verbose mode is enabled
log_message() {
    if [ "$VERBOSE" = true ]; then
        logger -t configure-host.sh "$1"
    fi
}

# Function to update hostname
update_hostname() {
    # Set the desired hostname
    desired_name="$1"
    current_name=$(hostname)
    # Check if the desired hostname is different from the current hostname
    if [ "$desired_name" != "$current_name" ]; then
        # If the desired hostname is different, set it using the 'hostnamectl' command with sudo privileges
        sudo hostnamectl set-hostname "$desired_name"  # Set the desired hostname
        # Log a message confirming that the hostname has been successfully updated to the desired value
        log_message "Hostname updated to $desired_name"
        # Print a message to the terminal indicating that the hostname has been updated
        echo "Hostname updated to $desired_name"
    else
        # If the desired hostname is the same as the current hostname, log a message stating it's already set
        log_message "Hostname is already set to $desired_name"
    fi
}

# Function to update IP address
update_ip_address() {
    # Replace old IP with new IP in /etc/hosts
    desired_ip="$1"
    current_ip=$(hostname -I | awk '{print $1}')

    if [ "$desired_ip" != "$current_ip" ]; then
        sudo sed -i "s/$current_ip/$desired_ip/g" /etc/hosts

        # Update netplan file
        # Replace the following line with appropriate command based on your netplan configuration
        # e.g., sudo sed -i "s/$current_ip/$desired_ip/g" /etc/netplan/01-netcfg.yaml

        log_message "IP address updated to $desired_ip"
        echo "IP address updated to $desired_ip"
    else
        log_message "IP address is already set to $desired_ip"
    fi
}

# Function to update /etc/hosts entry
update_host_entry() {
    # Add new host entry to /etc/hosts
    desired_name="$1"
    desired_ip="$2"
    if grep -q "$desired_name" /etc/hosts; then
        log_message "Host entry already exists for $desired_name with IP $desired_ip"
    else
        echo "$desired_ip    $desired_name" | sudo tee -a /etc/hosts >/dev/null
        log_message "Host entry added for $desired_name with IP $desired_ip"
        echo "Host entry added for $desired_name with IP $desired_ip"
    fi
}

# Ignore signals
trap '' SIGTERM SIGHUP SIGINT

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
    -verbose)
        VERBOSE=true
        ;;
    -name)
        shift
        update_hostname "$1"
        ;;
    -ip)
        shift
        update_ip_address "$1"
        ;;
    -hostentry)
        shift
        update_host_entry "$1" "$2"
        shift
        ;;
    *)
        echo "Unknown option: $key"
        ;;
    esac
    shift
done

exit 0

