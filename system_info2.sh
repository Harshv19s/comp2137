#!/bin/bash

#######################################################################
# Script: system_report.sh
# Description: Generates a system report including various system,
#              hardware, network, and status information.
# Author: Harshveer Singh
# Date: $(date)
#######################################################################

# Get system information
HOSTNAME=$(hostname) # Get the hostname of the system
UPTIME=$(uptime -p) # Get system uptime
OS=$(grep "PRETTY_NAME" /etc/os-release | cut -d'"' -f2) # Get Operating System name
IP_ADDRESS=$(hostname -I | awk '{print $1}') # Get primary IP address
CIDR=$(ip -o -f inet addr show | awk '/scope global/ {print $4}')
GATEWAY_IP=$(ip route | awk '/default/ {print $3}') # Get default gateway IP
DNS_SERVER=$(grep "nameserver" /etc/resolv.conf | awk '{print $2}') # Get DNS server IP

# Get hardware information
CPU_INFO=$(lscpu | awk '/Model name/ {print substr($0, index($0,$3))}') # Get CPU model
CPU_SPEED=$(sudo dmidecode -t processor | grep -E "Speed" | head -n 2) # Get CPU speed
RAM=$(free -h | awk '/Mem/ {print $2}') # Get total RAM size
DISK_INFO=$(lsblk -d -o NAME,MODEL,SIZE | awk '!/NAME/{print}') # Get disk information
VIDEO=$(lspci | grep -iE "vga|3d|display" | awk -F ": " '{print $2}') # Get video card information

# Get network information
NETWORK_CARD=$(lshw -class network | awk '/logical name/ {print $3}') # Get network interface name
FQDN=$(hostname -f) # Get fully qualified domain name
WHO_LOGGED_IN=$(who | cut -d' ' -f1 | sort -u | paste -sd ',' -) # Get logged in users

# Get system status information
DISK_SPACE=$(df -h --output=target,avail | awk 'NR>1 {print}') # Get disk space information
PROCESS_COUNT=$(ps aux | wc -l) # Get total number of processes
LOAD_AVERAGES=$(awk '{print $1 ", " $2 ", " $3}' /proc/loadavg) # Get load averages
MEMORY_ALLOC=$(free -m | awk '/Mem/ {print $3}') # Get used memory in MB
LISTENING_PORTS=$(ss -tuln | awk 'NR > 1 {print $4}' | cut -d ':' -f 2 | sort -n | uniq | paste -sd ', ') # Get listening ports
UFW_RULES=$(sudo ufw status | awk '/Status/ {print $2}') # Get UFW firewall status

# Output the system report
cat << EOF

########################### System Report #############################

System Information:
-------------------
Hostname: $HOSTNAME
Operating System: $OS
Uptime: $UPTIME

Hardware Information:
---------------------
CPU:$CPU_INFO
CPU Speed:
$CPU_SPEED
RAM: $RAM
Disk(s):
$DISK_INFO
Video Card: $VIDEO

Network Information:
--------------------
FQDN: $FQDN
Host Address: $IP_ADDRESS
Gateway IP: $GATEWAY_IP
DNS Server: $DNS_SERVER
InterfaceName: $NETWORK_CARD
IP Address:$CIDR
System Status:
--------------
Users Logged In: $WHO_LOGGED_IN
Disk Space:
$DISK_SPACE
Process Count: $PROCESS_COUNT
Load Averages: $LOAD_AVERAGES
Memory Allocation: $MEMORY_ALLOC MB
Listening Ports: $LISTENING_PORTS
UFW Rules: $UFW_RULES

#######################################################################

EOF
