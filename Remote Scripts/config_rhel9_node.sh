#!/bin/bash
# Script to configure RHEL 9 workstation worker with static IP and gather inventory details
# Run as root or with sudo

# Dynamically detect the first non-loopback interface
NETWORK_INTERFACE=$(ip link | grep -o '^[0-9]: [^:]*' | awk '{print $2}' | grep -v lo | head -n 1)
if [ -z "$NETWORK_INTERFACE" ]; then
    echo "Error: No non-loopback network interface found."
    exit 1
fi

# Find the connection name associated with the interface
CONNECTION_NAME=$(nmcli -t -f NAME,DEVICE connection show | grep ":$NETWORK_INTERFACE$" | cut -d: -f1)
if [ -z "$CONNECTION_NAME" ]; then
    echo "Error: No active connection found for interface $NETWORK_INTERFACE."
    echo "Creating a new connection..."
    CONNECTION_NAME="Wired connection $NETWORK_INTERFACE"
    nmcli con add type ethernet con-name "$CONNECTION_NAME" ifname "$NETWORK_INTERFACE"
fi

# Gather current info
echo "Current Configuration:"
echo "Hostname: $(hostname -f)"
echo "IP: $(ip addr show dev $NETWORK_INTERFACE | grep -o 'inet [0-9.]*' | awk '{print $2}' | head -n 1)"
echo "OS: $(cat /etc/redhat-release)"
echo "SSH User: $(whoami)"
echo "SSH Port: $(ss -tuln | grep :22 | awk '{print $5}' | cut -d: -f2 || echo '22')"

# Set static IP to 192.168.10.134
echo "Setting static IP to 192.168.10.134 on interface $NETWORK_INTERFACE with connection $CONNECTION_NAME..."
nmcli con mod "$CONNECTION_NAME" ipv4.addresses 192.168.10.134/24
nmcli con mod "$CONNECTION_NAME" ipv4.gateway 192.168.10.1
nmcli con mod "$CONNECTION_NAME" ipv4.method manual
nmcli con mod "$CONNECTION_NAME" ipv4.dns "8.8.8.8,8.8.4.4"
nmcli con up "$CONNECTION_NAME"

# Verify new IP
echo "New Configuration:"
echo "Hostname: $(hostname -f)"
echo "IP: $(ip addr show dev $NETWORK_INTERFACE | grep -o 'inet [0-9.]*' | awk '{print $2}' | head -n 1)"
echo "OS: $(cat /etc/redhat-release)"
echo "SSH User: $(whoami)"
echo "SSH Port: $(ss -tuln | grep :22 | awk '{print $5}' | cut -d: -f2 || echo '22')"
echo "Static IP set to 192.168.10.134 completed."
