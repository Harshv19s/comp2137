#!/bin/bash

# Function to display usage information
usage() {
    echo "Usage: $0 [-v]"
    echo "Options:"
    echo "  -v      Run in verbose mode"
    exit 1
}

# Default values
VERBOSE=false

# Parse command-line options
while getopts ":v" opt; do
    case ${opt} in
        v )
            VERBOSE=true
            ;;
        \? )
            usage
            ;;
    esac
done
shift $((OPTIND -1))

# Function to execute remote commands
execute_remote() {
    local remote_host="$1"
    local command="$2"
    if $VERBOSE; then
        ssh "$remote_host" -- "$command" -verbose
    else
        ssh "$remote_host" -- "$command"
    fi
}

# Transfer configure-host.sh script to servers and apply configurations
transfer_and_configure() {
    local remote_host="$1"
    scp configure-host.sh remoteadmin@"$remote_host":/root
    execute_remote "$remote_host" "/root/configure-host.sh -name $2 -ip $3 -hostentry $4 $5"
}

# Main function
main() {
    # Check if configure-host.sh exists
    if [ ! -f "configure-host.sh" ]; then
        echo "Error: configure-host.sh script not found."
        exit 1
    fi
    
    # Transfer and configure on server1-mgmt
    transfer_and_configure "server1-mgmt" "loghost" "192.168.16.3" "webhost" "192.168.16.4"

    # Transfer and configure on server2-mgmt
    transfer_and_configure "server2-mgmt" "webhost" "192.168.16.4" "loghost" "192.168.16.3"

    # Update /etc/hosts on local machine
    ./configure-host.sh -hostentry loghost 192.168.16.3
    ./configure-host.sh -hostentry webhost 192.168.16.4
}

# Check if verbose mode is enabled
if $VERBOSE; then
    echo "Verbose mode enabled."
fi

# Execute main function
main
