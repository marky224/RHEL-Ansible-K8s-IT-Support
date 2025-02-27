#!/bin/bash
# control-server.sh
# Configures a RHEL 9 server as an Ansible control node at 192.168.10.100

# Configuration variables
CONTROL_NODE_IP="192.168.10.100"  # Control node IP
NETWORK_INTERFACE="ens160"        # Network interface name
GATEWAY_IP="192.168.10.1"         # Gateway IP
CHECKIN_PORT="${CHECKIN_PORT:-8080}"  # Configurable check-in port
LOG_FILE="${LOG_FILE:-/var/log/ansible_control_setup.log}"

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
echo "$(date '+%Y-%m-%d %H:%M:%S') - Starting RHEL 9 control node configuration" >> "$LOG_FILE"

# Prompt for Red Hat subscription credentials interactively
echo "Please provide Red Hat subscription credentials:"
read -p "Username: " SUB_USERNAME
if [ -z "$SUB_USERNAME" ]; then
    echo "Error: Username cannot be empty" >&2
    echo "$(date) - Username prompt failed" >> "$LOG_FILE"
    exit 1
fi
read -s -p "Password: " SUB_PASSWORD
echo
if [ -z "$SUB_PASSWORD" ]; then
    echo "Error: Password cannot be empty" >&2
    echo "$(date) - Password prompt failed" >> "$LOG_FILE"
    exit 1
fi
echo "$(date) - Subscription credentials provided" >> "$LOG_FILE"

# Set static IP
echo "Configuring static IP $CONTROL_NODE_IP on $NETWORK_INTERFACE..." | tee -a "$LOG_FILE"
nmcli con mod "System $NETWORK_INTERFACE" ipv4.addresses "$CONTROL_NODE_IP/24" >> "$LOG_FILE" 2>&1 || {
    echo "Error: Failed to set IP address" >&2
    echo "$(date) - IP configuration failed" >> "$LOG_FILE"
    exit 1
}
nmcli con mod "System $NETWORK_INTERFACE" ipv4.gateway "$GATEWAY_IP" >> "$LOG_FILE" 2>&1
nmcli con mod "System $NETWORK_INTERFACE" ipv4.method manual >> "$LOG_FILE" 2>&1
nmcli con up "System $NETWORK_INTERFACE" >> "$LOG_FILE" 2>&1 || {
    echo "Error: Failed to apply network settings" >&2
    echo "$(date) - Network activation failed" >> "$LOG_FILE"
    exit 1
}
echo "$(date) - Static IP set to $CONTROL_NODE_IP" >> "$LOG_FILE"

# Check for existing Ansible installation
if command -v ansible >/dev/null 2>&1; then
    echo "Ansible already installed, skipping installation..." | tee -a "$LOG_FILE"
    echo "$(date) - Ansible detected, skipping install" >> "$LOG_FILE"
else
    # Update system and install prerequisites
    echo "Updating system and installing required packages..." | tee -a "$LOG_FILE"
    dnf update -y >> "$LOG_FILE" 2>&1 || {
        echo "Error: Failed to update system" >&2
        echo "$(date) - System update failed" >> "$LOG_FILE"
        exit 1
    }
    dnf install -y python3 curl >> "$LOG_FILE" 2>&1 || {
        echo "Error: Failed to install python3 and curl" >&2
        echo "$(date) - Package installation failed" >> "$LOG_FILE"
        exit 1
    }

    # Register RHEL subscription and install Ansible
    echo "Registering RHEL subscription..." | tee -a "$LOG_FILE"
    subscription-manager register --username "$SUB_USERNAME" --password "$SUB_PASSWORD" --auto-attach >> "$LOG_FILE" 2>&1 || {
        echo "Error: Failed to register subscription" >&2
        echo "$(date) - Subscription registration failed" >> "$LOG_FILE"
        exit 1
    }
    subscription-manager repos --enable ansible-2-for-rhel-9-x86_64-rpms >> "$LOG_FILE" 2>&1 || {
        echo "Error: Failed to enable Ansible repo" >&2
        echo "$(date) - Ansible repo enable failed" >> "$LOG_FILE"
        exit 1
    }
    dnf install -y ansible-core >> "$LOG_FILE" 2>&1 || {
        echo "Error: Failed to install ansible-core" >&2
        echo "$(date) - Ansible installation failed" >> "$LOG_FILE"
        exit 1
    }
    echo "$(date) - Ansible installed successfully" >> "$LOG_FILE"
fi

# Check for existing SSH key pair
if [ ! -f "/root/.ssh/id_rsa" ]; then
    echo "Generating SSH key pair..." | tee -a "$LOG_FILE"
    ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N "" >> "$LOG_FILE" 2>&1 || {
        echo "Error: Failed to generate SSH key pair" >&2
        echo "$(date) - SSH key generation failed" >> "$LOG_FILE"
        exit 1
    }
    echo "$(date) - SSH key pair generated" >> "$LOG_FILE"
else
    echo "SSH key pair already exists, skipping generation..." | tee -a "$LOG_FILE"
    echo "$(date) - Existing SSH key detected" >> "$LOG_FILE"
fi

# Install Python scripts for HTTPS services if not present
if [ ! -f "checkin_listener.py" ] || [ ! -f "ssh_key_server.py" ]; then
    echo "Installing check-in listener and SSH key server..." | tee -a "$LOG_FILE"
    curl -O "https://raw.githubusercontent.com/yourusername/rhel-ansible-k8s-it-support/main/scripts/checkin_listener.py" >> "$LOG_FILE" 2>&1 || {
        echo "Error: Failed to download checkin_listener.py" >&2
        echo "$(date) - Check-in listener download failed" >> "$LOG_FILE"
        exit 1
    }
    curl -O "https://raw.githubusercontent.com/yourusername/rhel-ansible-k8s-it-support/main/scripts/ssh_key_server.py" >> "$LOG_FILE" 2>&1 || {
        echo "Error: Failed to download ssh_key_server.py" >&2
        echo "$(date) - SSH key server download failed" >> "$LOG_FILE"
        exit 1
    }
    chmod +x checkin_listener.py ssh_key_server.py
    echo "$(date) - HTTPS service scripts installed" >> "$LOG_FILE"
else
    echo "HTTPS service scripts already present, skipping download..." | tee -a "$LOG_FILE"
    echo "$(date) - Existing HTTPS scripts detected" >> "$LOG_FILE"
fi

# Start HTTPS services (background) if not running
if ! ps aux | grep -q "[c]heckin_listener.py"; then
    echo "Starting check-in listener..." | tee -a "$LOG_FILE"
    python3 checkin_listener.py & >> "$LOG_FILE" 2>&1
fi
if ! ps aux | grep -q "[s]sh_key_server.py"; then
    echo "Starting SSH key server..." | tee -a "$LOG_FILE"
    python3 ssh_key_server.py & >> "$LOG_FILE" 2>&1
fi
sleep 2  # Give services time to start
if ! ps aux | grep -q "[c]heckin_listener.py"; then
    echo "Error: Check-in listener failed to start" >&2
    echo "$(date) - Check-in listener start failed" >> "$LOG_FILE"
    exit 1
fi
if ! ps aux | grep -q "[s]sh_key_server.py"; then
    echo "Error: SSH key server failed to start" >&2
    echo "$(date) - SSH key server start failed" >> "$LOG_FILE"
    exit 1
fi
echo "$(date) - HTTPS services started" >> "$LOG_FILE"

# Open firewall port for HTTPS services
echo "Opening port $CHECKIN_PORT in firewall..." | tee -a "$LOG_FILE"
firewall-cmd --add-port="$CHECKIN_PORT/tcp" --permanent >> "$LOG_FILE" 2>&1 && firewall-cmd --reload >> "$LOG_FILE" 2>&1 || {
    echo "Error: Failed to configure firewall" >&2
    echo "$(date) - Firewall configuration failed" >> "$LOG_FILE"
    exit 1
}
echo "$(date) - Firewall configured for port $CHECKIN_PORT" >> "$LOG_FILE"

# Completion message
echo "RHEL 9 control node configured at $CONTROL_NODE_IP" | tee -a "$LOG_FILE"
echo "$(date) - Configuration completed successfully" >> "$LOG_FILE"
echo "Next steps: Update ansible/inventory/inventory.yml with remote node details and test connectivity."
