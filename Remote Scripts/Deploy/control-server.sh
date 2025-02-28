#!/bin/bash
# control-server.sh
# Configures a RHEL 9 server as an Ansible control node at 192.168.10.100 with Docker

# Configuration variables
CONTROL_NODE_IP="192.168.10.100"
GATEWAY_IP="192.168.10.1"
CHECKIN_PORT="${CHECKIN_PORT:-8080}"
LOG_FILE="${LOG_FILE:-/var/log/ansible_control_setup.log}"
CA_CERT="/etc/pki/tls/certs/control_node_ca.crt"
CA_KEY="/etc/pki/tls/private/control_node_ca.key"
TIMEOUT=30  # Timeout in seconds for network operations
SCRIPTS_DIR="/usr/local/bin"
GITHUB_REPO="https://raw.githubusercontent.com/marky224/rhel-ansible-k8s-it-support/Remote%20Scripts/Deploy"
DOCKER_IMAGE="ansible-control-services:latest"

# Function to log messages with timestamp
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Rotate logs if larger than 10MB
rotate_logs() {
    if [ -f "$LOG_FILE" ] && [ $(stat -c%s "$LOG_FILE") -gt 10485760 ]; then
        mv "$LOG_FILE" "${LOG_FILE}.$(date '+%Y%m%d%H%M%S')"
        touch "$LOG_FILE" && chmod 644 "$LOG_FILE"
        log "Log file rotated due to size exceeding 10MB."
    fi
}

# Ensure script runs with sudo if not root
if [ "$EUID" -ne 0 ]; then
    log "Error: Please run as root or with sudo"
    exit 1
fi

# Setup logging
touch "$LOG_FILE" 2>/dev/null || { log "Error: Cannot create log file at $LOG_FILE"; exit 1; }
chmod 644 "$LOG_FILE"
rotate_logs
log "Starting RHEL 9 control node configuration"

# Verify RHEL 9
if ! grep -q "Red Hat Enterprise Linux 9" /etc/os-release; then
    log "Error: This script is designed for RHEL 9 only"
    exit 2
fi

# Prompt for Red Hat subscription credentials interactively
log "Prompting for Red Hat subscription credentials..."
read -p "Enter Red Hat subscription username: " SUB_USERNAME
if [ -z "$SUB_USERNAME" ]; then
    log "Error: Username cannot be empty"
    exit 1
fi
read -s -p "Enter Red Hat subscription password: " SUB_PASSWORD
echo
if [ -z "$SUB_PASSWORD" ]; then
    log "Error: Password cannot be empty"
    exit 1
fi
log "Subscription credentials provided"

# Dynamically detect active interface
log "Detecting active network interface..."
INTERFACE=$(ip link | grep -E '^[0-9]+: ' | grep -v 'lo:' | grep 'state UP' | awk -F: '{print $2}' | tr -d ' ' | head -n 1)
if [ -z "$INTERFACE" ]; then
    log "Warning: No active UP interface found. Using first available..."
    INTERFACE=$(ip link | grep -E '^[0-9]+: ' | grep -v 'lo:' | awk -F: '{print $2}' | tr -d ' ' | head -n 1)
    if [ -z "$INTERFACE" ]; then
        log "Error: No network interface found"
        exit 1
    fi
fi
log "Using interface: $INTERFACE"

# Detect NetworkManager connection name
CONNECTION_NAME=$(nmcli con show --active | grep "$INTERFACE" | awk '{print $1}' | head -n 1)
if [ -z "$CONNECTION_NAME" ]; then
    log "Warning: No active connection found. Using first match..."
    CONNECTION_NAME=$(nmcli con show | grep "$INTERFACE" | awk '{print $1}' | head -n 1)
    if [ -z "$CONNECTION_NAME" ]; then
        log "Error: No NetworkManager connection found for $INTERFACE"
        exit 1
    fi
fi
log "Using connection name: $CONNECTION_NAME"

# Set static IP idempotently
log "Configuring static IP $CONTROL_NODE_IP on $INTERFACE..."
CURRENT_IP=$(nmcli con show "$CONNECTION_NAME" | grep 'ipv4.addresses' | awk '{print $2}' | cut -d'/' -f1)
if [ "$CURRENT_IP" != "$CONTROL_NODE_IP" ]; then
    nmcli con mod "$CONNECTION_NAME" ipv4.addresses "$CONTROL_NODE_IP/24" \
        ipv4.gateway "$GATEWAY_IP" ipv4.dns "$DNS1 $DNS2" ipv4.method manual || {
        log "Error: Failed to set IP address"
        exit 1
    }
    nmcli con up "$CONNECTION_NAME" || {
        log "Error: Failed to apply network settings"
        exit 1
    }
    log "Static IP set to $CONTROL_NODE_IP"
else
    log "Static IP already set to $CONTROL_NODE_IP"
fi

# Install prerequisites, Ansible, and Docker
if ! command -v ansible >/dev/null 2>&1 || ! command -v docker >/dev/null 2>&1; then
    log "Updating system and installing required packages..."
    subscription-manager register --username "$SUB_USERNAME" --password "$SUB_PASSWORD" --auto-attach || {
        log "Error: Failed to register subscription"
        exit 1
    }
    dnf update -y || {
        log "Error: Failed to update system"
        exit 1
    }
    dnf install -y python3 curl openssl docker || {
        log "Error: Failed to install python3, curl, openssl, or docker"
        exit 1
    }
    subscription-manager repos --enable ansible-2-for-rhel-9-x86_64-rpms || {
        log "Error: Failed to enable Ansible repo"
        exit 1
    }
    dnf install -y ansible-core || {
        log "Error: Failed to install ansible-core"
        exit 1
    }
    systemctl enable docker --now || {
        log "Error: Failed to enable/start Docker"
        exit 1
    }
    log "Ansible and Docker installed successfully"
else
    log "Ansible and Docker already installed"
fi

# Generate or verify SSH key pair
if [ ! -f "/root/.ssh/id_rsa" ]; then
    log "Generating SSH key pair..."
    ssh-keygen -t rsa -b 4096 -f /root/.ssh/id_rsa -N "" || {
        log "Error: Failed to generate SSH key pair"
        exit 1
    }
    log "SSH key pair generated"
else
    log "SSH key pair already exists"
fi
chmod 700 /root/.ssh
chmod 600 /root/.ssh/id_rsa*

# Enable and configure SSH service
log "Configuring SSH service..."
if ! systemctl is-active sshd >/dev/null 2>&1; then
    systemctl enable sshd --now || {
        log "Error: Failed to enable/start sshd"
        exit 1
    }
    log "SSH service enabled and started"
fi
if ! grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config; then
    sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
    systemctl restart sshd || {
        log "Error: Failed to restart sshd after config change"
        exit 1
    }
    log "SSH configured to disable password authentication"
fi

# Generate or verify CA certificate
if [ ! -f "$CA_CERT" ] || [ ! -f "$CA_KEY" ]; then
    log "Generating self-signed CA certificate..."
    openssl req -x509 -newkey rsa:4096 -keyout "$CA_KEY" -out "$CA_CERT" -days 365 -nodes \
        -subj "/CN=$CONTROL_NODE_IP" || {
        log "Error: Failed to generate CA certificate"
        exit 1
    }
    chmod 600 "$CA_KEY"
    chmod 644 "$CA_CERT"
    log "CA certificate generated at $CA_CERT"
else
    log "CA certificate already exists at $CA_CERT"
fi

# Create temporary directory for Docker build
TEMP_DIR=$(mktemp -d)
log "Created temporary directory $TEMP_DIR for Docker build"

# Download Dockerfile and scripts from GitHub
log "Downloading Docker files from GitHub..."
for FILE in "Dockerfile" "entrypoint.sh" "checkin_listener.py" "ssh_key_server.py"; do
    curl -o "$TEMP_DIR/$FILE" "$GITHUB_REPO/$FILE" || {
        log "Error: Failed to download $FILE from $GITHUB_REPO/$FILE"
        log "Ensure the file exists in the GitHub repository and the system has internet access."
        rm -rf "$TEMP_DIR"
        exit 1
    }
    chmod +x "$TEMP_DIR/$FILE"
done
log "Docker files downloaded to $TEMP_DIR"

# Build Docker image
log "Building Docker image $DOCKER_IMAGE..."
docker build -t "$DOCKER_IMAGE" "$TEMP_DIR" || {
    log "Error: Failed to build Docker image"
    rm -rf "$TEMP_DIR"
    exit 1
}
rm -rf "$TEMP_DIR"
log "Docker image $DOCKER_IMAGE built successfully"

# Run Docker containers
log "Starting Docker containers for HTTPS services..."
docker stop checkin-listener ssh-key-server >/dev/null 2>&1 || true  # Stop if running
docker rm checkin-listener ssh-key-server >/dev/null 2>&1 || true    # Remove if exists
docker run -d --name checkin-listener \
    -p "$CHECKIN_PORT:$CHECKIN_PORT" \
    -v "$CA_CERT:/certs/control_node_ca.crt:ro" \
    -v "$CA_KEY:/certs/control_node_ca.key:ro" \
    -e SERVICE=checkin_listener \
    -e PORT="$CHECKIN_PORT" \
    "$DOCKER_IMAGE" || {
    log "Error: Failed to start checkin-listener container"
    exit 1
}
docker run -d --name ssh-key-server \
    -p "$((CHECKIN_PORT+1)):$CHECKIN_PORT" \
    -v "$CA_CERT:/certs/control_node_ca.crt:ro" \
    -v "$CA_KEY:/certs/control_node_ca.key:ro" \
    -v "/root/.ssh/id_rsa.pub:/app/id_rsa.pub:ro" \
    -e SERVICE=ssh_key_server \
    -e PORT="$CHECKIN_PORT" \
    "$DOCKER_IMAGE" || {
    log "Error: Failed to start ssh-key-server container"
    exit 1
}
log "Docker containers started (checkin-listener on $CHECKIN_PORT, ssh-key-server on $((CHECKIN_PORT+1)))"

# Configure firewall
log "Configuring firewall for SSH and ports $CHECKIN_PORT, $((CHECKIN_PORT+1))..."
if ! firewall-cmd --list-services | grep -q ssh; then
    firewall-cmd --permanent --add-service=ssh || {
        log "Error: Failed to add SSH to firewall"
        exit 1
    }
fi
if ! firewall-cmd --list-ports | grep -q "$CHECKIN_PORT/tcp"; then
    firewall-cmd --permanent --add-port="$CHECKIN_PORT/tcp" || {
        log "Error: Failed to open port $CHECKIN_PORT"
        exit 1
    }
fi
if ! firewall-cmd --list-ports | grep -q "$((CHECKIN_PORT+1))/tcp"; then
    firewall-cmd --permanent --add-port="$((CHECKIN_PORT+1))/tcp" || {
        log "Error: Failed to open port $((CHECKIN_PORT+1))"
        exit 1
    }
fi
firewall-cmd --reload || {
    log "Error: Failed to reload firewall"
    exit 1
}
log "Firewall configured"

# Verify configuration
log "Verifying network configuration..."
ip addr show "$INTERFACE" | tee -a "$LOG_FILE"
log "Control node setup complete at $CONTROL_NODE_IP"
log "Next steps: Update ansible/inventory/inventory.yml with remote node details and test connectivity."
exit 0
