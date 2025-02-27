#!/bin/bash
# rhel9_connect.sh
# Configures RHEL 9 workstation at 192.168.10.134 to connect to Ansible control node at 192.168.10.100 with HTTPS key exchange

# Configuration variables
CONTROL_NODE_IP="192.168.10.100"  # Ansible control node IP
WORKSTATION_IP="192.168.10.134"   # Target workstation IP
USER="${USER:-root}"              # Default to root; override with env var
CHECKIN_PORT="${CHECKIN_PORT:-8080}"  # Configurable check-in port
SSH_KEY_URL="https://$CONTROL_NODE_IP:$CHECKIN_PORT/ssh_key"  # HTTPS SSH key endpoint
LOG_FILE="${LOG_FILE:-/var/log/ansible_connect.log}"

# Ensure script runs with sudo if not root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo" >&2
    exit 1
fi

# Setup logging
if ! touch "$LOG_FILE" 2>/dev/null; then
    echo "Cannot create log file at $LOG_FILE" >&2
    exit 1
fi
chmod 644 "$LOG_FILE"
echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting RHEL 9 workstation configuration" >> "$LOG_FILE"

# Validate workstation IP
CURRENT_IP=$(ip addr show | grep -oP '(?<=inet )192\.168\.10\.\d+' | head -n1)
if [ "$CURRENT_IP" != "$WORKSTATION_IP" ]; then
    echo "Error: Script intended for $WORKSTATION_IP, but running on $CURRENT_IP" >&2
    echo "$(date) - IP mismatch: expected $WORKSTATION_IP, got $CURRENT_IP" >> "$LOG_FILE"
    exit 1
fi
echo "$(date) - IP validated: $CURRENT_IP" >> "$LOG_FILE"

# Update system and install prerequisites
echo "Updating system and installing SSH server and curl..." | tee -a "$LOG_FILE"
dnf update -y >> "$LOG_FILE" 2>&1 || {
    echo "Error: Failed to update system" >&2
    echo "$(date) - System update failed" >> "$LOG_FILE"
    exit 1
}
dnf install -y openssh-server curl >> "$LOG_FILE" 2>&1 || {
    echo "Error: Failed to install openssh-server and curl" >&2
    echo "$(date) - Package installation failed" >> "$LOG_FILE"
    exit 1
}
echo "$(date) - Packages installed successfully" >> "$LOG_FILE"

# Configure SSH
echo "Configuring SSH..." | tee -a "$LOG_FILE"
systemctl enable sshd >> "$LOG_FILE" 2>&1 && systemctl start sshd >> "$LOG_FILE" 2>&1 || {
    echo "Error: Failed to enable/start SSH" >&2
    echo "$(date) - SSH configuration failed" >> "$LOG_FILE"
    exit 1
}
echo "$(date) - SSH configured and started" >> "$LOG_FILE"

# Open SSH port in firewall
echo "Opening SSH port in firewall..." | tee -a "$LOG_FILE"
if firewall-cmd --state >/dev/null 2>&1; then
    firewall-cmd --add-service=ssh --permanent >> "$LOG_FILE" 2>&1 && firewall-cmd --reload >> "$LOG_FILE" 2>&1 || {
        echo "Error: Failed to configure firewall" >&2
        echo "$(date) - Firewall configuration failed" >> "$LOG_FILE"
        exit 1
    }
else
    echo "Warning: Firewalld not active" | tee -a "$LOG_FILE"
fi
echo "$(date) - Firewall configured (if active)" >> "$LOG_FILE"

# Automated SSH key exchange via HTTPS
echo "Fetching control node's SSH public key over HTTPS..." | tee -a "$LOG_FILE"
mkdir -p ~/.ssh && chmod 700 ~/.ssh >> "$LOG_FILE" 2>&1 || {
    echo "Error: Failed to create SSH directory" >&2
    echo "$(date) - SSH directory creation failed" >> "$LOG_FILE"
    exit 1
}
# Using --insecure for self-signed certs; replace with proper CA cert in production
curl --insecure -s "$SSH_KEY_URL" >> ~/.ssh/authorized_keys 2>>"$LOG_FILE" || {
    echo "Error: Failed to fetch SSH key from $SSH_KEY_URL" >&2
    echo "$(date) - SSH key fetch failed" >> "$LOG_FILE"
    exit 1
}
chmod 600 ~/.ssh/authorized_keys >> "$LOG_FILE" 2>&1 || {
    echo "Warning: Failed to set permissions on authorized_keys" | tee -a "$LOG_FILE"
}
echo "$(date) - SSH key added successfully" >> "$LOG_FILE"

# Send check-in to control node with retry logic
echo "Sending check-in to control node..." | tee -a "$LOG_FILE"
HOSTNAME=$(hostname)
for i in {1..3}; do
    curl --insecure -X POST -d "hostname=$HOSTNAME&ip=$WORKSTATION_IP&os=rhel9" "https://$CONTROL_NODE_IP:$CHECKIN_PORT/checkin" >> "$LOG_FILE" 2>&1 && {
        echo "$(date) - Check-in successful on attempt $i" >> "$LOG_FILE"
        break
    }
    echo "$(date) - Check-in attempt $i failed" >> "$LOG_FILE"
    sleep 5
done || {
    echo "Error: Failed to send check-in after 3 attempts" >&2
    echo "$(date) - Check-in failed" >> "$LOG_FILE"
    exit 1
}

# Completion message
echo "RHEL 9 workstation at $WORKSTATION_IP configured for Ansible control at $CONTROL_NODE_IP" | tee -a "$LOG_FILE"
echo "$(date) - Configuration completed successfully" >> "$LOG_FILE"
