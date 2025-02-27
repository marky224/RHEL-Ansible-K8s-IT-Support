#!/bin/bash
# Configures RHEL 9 workstation at 192.168.10.134 for Ansible management via SSH

# Variables
CONTROL_NODE="192.168.10.100"
IP_ADDRESS="192.168.10.134"
SUBNET_MASK="24"  # 255.255.255.0 in CIDR
GATEWAY="192.168.10.1"
DNS1="8.8.8.8"
DNS2="8.8.4.4"
LOG_FILE="/var/log/ansible_connect.log"
SSH_KEY_URL="https://$CONTROL_NODE:8080/ssh_key"
CHECKIN_URL="https://$CONTROL_NODE:8080/checkin"
CA_CERT="/etc/pki/tls/certs/control_node_ca.crt"  # Adjust path if CA cert is pre-installed

# Function to log messages with timestamp
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Ensure log file exists and is writable
touch "$LOG_FILE" 2>/dev/null || { sudo touch "$LOG_FILE" && sudo chmod 644 "$LOG_FILE"; }
log "Starting RHEL 9 configuration for Ansible management..."

# Check for root privileges
if [ "$EUID" -ne 0 ]; then
    log "Error: This script must be run as root. Use sudo."
    exit 1
fi

# Prompt for dynamic access token (for production security)
read -sp "Enter access token for $CONTROL_NODE: " ACCESS_TOKEN
echo
if [ -z "$ACCESS_TOKEN" ]; then
    log "Error: Access token required for secure connection."
    exit 1
fi

# Dynamically detect active interface
log "Detecting active network interface..."
INTERFACE=$(ip link | grep -E '^[0-9]+: ' | grep -v 'lo:' | grep 'state UP' | awk -F: '{print $2}' | tr -d ' ' | head -n 1)
if [ -z "$INTERFACE" ]; then
    log "Error: No active network interface found."
    exit 1
fi
log "Using interface: $INTERFACE"

# Dynamically detect active connection name
log "Detecting active NetworkManager connection..."
CONNECTION_NAME=$(nmcli con show --active | grep "$INTERFACE" | awk '{print $1}' | head -n 1)
if [ -z "$CONNECTION_NAME" ]; then
    log "Error: No active NetworkManager connection found for $INTERFACE."
    exit 1
fi
log "Using connection name: $CONNECTION_NAME"

# Set static IP
log "Setting static IP to $IP_ADDRESS..."
nmcli con mod "$CONNECTION_NAME" ipv4.addresses "$IP_ADDRESS/$SUBNET_MASK" \
    ipv4.gateway "$GATEWAY" ipv4.dns "$DNS1 $DNS2" ipv4.method manual || {
    log "Error: Failed to set static IP."
    exit 1
}
nmcli con down "$CONNECTION_NAME" && nmcli con up "$CONNECTION_NAME" || {
    log "Error: Failed to restart network connection."
    exit 1
}
log "Static IP configuration applied."

# Install prerequisites
log "Installing openssh-server and curl..."
subscription-manager register --auto-attach || log "Warning: Subscription registration failed. Updates may be limited."
dnf install -y openssh-server curl || {
    log "Error: Failed to install required packages."
    exit 1
}

# Enable and start SSH service
log "Enabling SSH service..."
systemctl enable sshd --now || {
    log "Error: Failed to enable/start sshd."
    exit 1
}

# Configure firewall
log "Configuring firewall for SSH..."
firewall-cmd --permanent --add-service=ssh && firewall-cmd --reload || {
    log "Error: Failed to configure firewall."
    exit 1
}

# Set up SSH key exchange with token and certificate validation
log "Fetching SSH public key from $SSH_KEY_URL..."
mkdir -p /root/.ssh && chmod 700 /root/.ssh
if [ -f "$CA_CERT" ]; then
    curl -s --cacert "$CA_CERT" --header "Authorization: Bearer $ACCESS_TOKEN" "$SSH_KEY_URL" >> /root/.ssh/authorized_keys || {
        log "Error: Failed to fetch SSH key from $CONTROL_NODE with certificate validation."
        exit 1
    }
else
    log "Warning: CA certificate not found at $CA_CERT. Skipping validation (testing mode)..."
    curl -k -s --header "Authorization: Bearer $ACCESS_TOKEN" "$SSH_KEY_URL" >> /root/.ssh/authorized_keys || {
        log "Error: Failed to fetch SSH key from $CONTROL_NODE."
        exit 1
    }
fi
chmod 600 /root/.ssh/authorized_keys
log "SSH key added to /root/.ssh/authorized_keys."

# Send check-in to control node with retries
log "Sending check-in to $CHECKIN_URL..."
HOSTNAME=$(hostname)
OS="rhel9"
CHECKIN_DATA="hostname=$HOSTNAME&ip=$IP_ADDRESS&os=$OS"
for attempt in {1..3}; do
    if [ -f "$CA_CERT" ]; then
        curl -s --cacert "$CA_CERT" --header "Authorization: Bearer $ACCESS_TOKEN" --data "$CHECKIN_DATA" "$CHECKIN_URL" && {
            log "Check-in successful."
            break
        }
    else
        curl -k -s --header "Authorization: Bearer $ACCESS_TOKEN" --data "$CHECKIN_DATA" "$CHECKIN_URL" && {
            log "Check-in successful."
            break
        }
    fi
    log "Check-in attempt $attempt failed. Retrying in 5 seconds..."
    sleep 5
done
if [ "$attempt" -eq 3 ]; then
    log "Error: Check-in failed after 3 attempts."
    exit 1
fi

# Verify configuration
log "Verifying network configuration..."
ip addr show "$INTERFACE" | tee -a "$LOG_FILE"
nmcli con show "$CONNECTION_NAME" | grep -E 'ipv4.addresses|ipv4.gateway|ipv4.dns' | tee -a "$LOG_FILE"

log "RHEL 9 workstation at $IP_ADDRESS configured successfully for Ansible management."
exit 0
