#!/bin/bash
echo "Setting static IP address to 192.168.10.134..."

# Set variables
INTERFACE="eth0"
IP_ADDRESS="192.168.10.134"
SUBNET_MASK="24"  # CIDR notation for 255.255.255.0
GATEWAY="192.168.10.1"
DNS1="8.8.8.8"
DNS2="8.8.4.4"
CONNECTION_NAME="Wired connection 1"  # Default name, adjust if needed

# Check if the interface exists
if ip link show "$INTERFACE" > /dev/null 2>&1; then
    echo "Interface $INTERFACE found."
else
    echo "Error: Interface $INTERFACE not found. Please check the interface name and update the script."
    exit 1
fi

# Configure static IP using nmcli
nmcli con mod "$CONNECTION_NAME" ipv4.addresses "$IP_ADDRESS/$SUBNET_MASK"
nmcli con mod "$CONNECTION_NAME" ipv4.gateway "$GATEWAY"
nmcli con mod "$CONNECTION_NAME" ipv4.dns "$DNS1 $DNS2"
nmcli con mod "$CONNECTION_NAME" ipv4.method manual

# Restart the connection to apply changes
nmcli con down "$CONNECTION_NAME"
nmcli con up "$CONNECTION_NAME"

echo "IP address and DNS settings applied."
echo "Verifying configuration..."
ip addr show "$INTERFACE"
nmcli con show "$CONNECTION_NAME" | grep -E 'ipv4.addresses|ipv4.gateway|ipv4.dns'

exit 0
