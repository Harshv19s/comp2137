#!/bin/bash

# Function to display messages with formatting
print_message() {
    echo "********"
    echo "$1"
    echo "********"
}

# Function to update the netplan configuration
update_netplan() {
    print_message "Updating Netplan Configuration"
    local netplan_config="/etc/netplan/50-cloud-init.yaml"

    if [ ! -f "$netplan_config" ]; then
        echo "Error: Netplan configuration file not found: $netplan_config"
        exit 1
    fi

    # Define the new configuration for the 192.168.16 network interface
    local new_config="  addresses:
    - 192.168.16.21/24
  gateway4: 192.168.16.2
  nameservers:
    addresses: [192.168.16.2]
    search: [home.arpa, localdomain]"

    # Define the private management network interface
    local mgmt_interface="eth0"  # Assuming this is the private management interface

    # Update netplan configuration with the new configuration
    awk -v mgmt_interface="$mgmt_interface" -v new_config="$new_config" '
        BEGIN { found=0 }
        $0 ~ mgmt_interface { found=1 }
        found && /^$/ { print new_config; found=0 }
        { print }
    ' "$netplan_config" | sudo tee "$netplan_config" >/dev/null

    # Apply netplan configuration
    sudo netplan apply
}

# Function to update the /etc/hosts file
update_hosts() {
    print_message "Updating /etc/hosts File"
    local new_entry="192.168.16.21    server1"

    # Remove old entry if present
    sudo sed -i '/^192\.168\.16\.21/d' /etc/hosts

    # Add new entry
    echo "$new_entry" | sudo tee -a /etc/hosts >/dev/null
}

# Function to install Apache2
install_apache() {
    print_message "Installing Apache2"
    sudo apt update
    sudo apt install -y apache2
}

# Function to install Squid
install_squid() {
    print_message "Installing Squid"
    sudo apt update
    sudo apt install -y squid
}

# Function to start and enable Apache2 service
start_apache() {
    print_message "Starting and Enabling Apache2 Service"
    sudo systemctl start apache2
    sudo systemctl enable apache2
}

# Function to start and enable Squid service
start_squid() {
    print_message "Starting and Enabling Squid Service"
    sudo systemctl start squid
    sudo systemctl enable squid
}

# Function to configure UFW firewall rules
configure_firewall() {
    print_message "Configuring Firewall with UFW"
    
    # Enable UFW
    sudo ufw enable

    # Allow SSH on port 22 only on the management network
    sudo ufw allow from 192.168.16.0/24 to any port 22

    # Allow HTTP on both interfaces
    sudo ufw allow http

    # Allow web proxy on both interfaces (assuming default Squid proxy port 3128)
    sudo ufw allow 3128

    # Reload UFW to apply changes
    sudo ufw reload
}

# Function to create user accounts with specified configuration
create_users() {
    print_message "Creating User Accounts"

    # List of users to create
    local users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")

    # Create users with home directory and bash shell
    for user in "${users[@]}"; do
        sudo useradd -m -s /bin/bash "$user"
        echo "User '$user' created."

        # Generate RSA and Ed25519 keys for the user
        sudo -u "$user" ssh-keygen -t rsa -N "" -f "/home/$user/.ssh/id_rsa"
        sudo -u "$user" ssh-keygen -t ed25519 -N "" -f "/home/$user/.ssh/id_ed25519"

        # Append RSA and Ed25519 public keys to authorized_keys file
        cat "/home/$user/.ssh/id_rsa.pub" | sudo -u "$user" tee -a "/home/$user/.ssh/authorized_keys" >/dev/null
        cat "/home/$user/.ssh/id_ed25519.pub" | sudo -u "$user" tee -a "/home/$user/.ssh/authorized_keys" >/dev/null

        echo "SSH keys generated and added for user '$user'."
    done
}

# Function to grant sudo access to dennis
grant_sudo_access() {
    print_message "Granting Sudo Access to Dennis"
    sudo usermod -aG sudo dennis
    echo "Sudo access granted to user 'dennis'."
}

# Main script

# Update netplan configuration
update_netplan

# Update /etc/hosts file
update_hosts

# Install Apache2
install_apache

# Start and enable Apache2 service
start_apache

# Install Squid
install_squid

# Start and enable Squid service
start_squid

# Configure firewall rules using UFW
configure_firewall

# Create user accounts
create_users

# Grant sudo access to dennis
grant_sudo_access

