#!/bin/bash

# setup-rhel-workstation-node.sh
# Automates RHEL 9 workstation setup as an AD-joined remote node

# Exit on any error
set -e

# Variables
HOSTNAME="rhel-ws01.msp.local"
STATIC_IP="192.168.0.13"
NETMASK="255.255.255.0"
GATEWAY="192.168.0.1"       # UniFi Express default
DNS="192.168.0.10"          # ADDC IP
DOMAIN="msp.local"
NETBIOS="MSP"
DC_IP="192.168.0.10"
DC_HOSTNAME="dc01.msp.local"
AD_ADMIN="Administrator"
INTERFACE=$(nmcli -t -f NAME con show --active | head -n 1)  # Dynamic interface detection
LOGFILE="/var/log/rhel-ad-setup.log"

# Ensure script runs as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo." >&2
    exit 1
fi

# Function to log messages
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOGFILE"
}

log "Starting RHEL 9 workstation node setup for $DOMAIN"

# 1. Set hostname
log "Setting hostname to $HOSTNAME"
hostnamectl set-hostname "$HOSTNAME"

# 2. Configure static IP
log "Configuring static IP: $STATIC_IP on interface: $INTERFACE"
if [ -z "$INTERFACE" ]; then
    log "ERROR: No active network interface found."
    exit 1
fi
nmcli con mod "$INTERFACE" ipv4.addresses "$STATIC_IP/24" ipv4.gateway "$GATEWAY" ipv4.dns "$DNS" ipv4.method manual
nmcli con up "$INTERFACE"
log "Network configured: IP=$STATIC_IP, Gateway=$GATEWAY, DNS=$DNS"

# 3. Update /etc/hosts
log "Updating /etc/hosts"
cat << EOF > /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
$DC_IP      $DC_HOSTNAME  ${DC_HOSTNAME%%.*}
$STATIC_IP  $HOSTNAME  ${HOSTNAME%%.*}
EOF

# 4. Install updates
log "Installing system updates"
dnf update -y || { log "ERROR: Failed to update system"; exit 1; }

# 5. Install AD integration packages
log "Installing AD integration packages"
dnf install -y realmd sssd oddjob oddjob-mkhomedir adcli samba-common-tools chrony || { log "ERROR: Failed to install packages"; exit 1; }

# 6. Configure time sync with DC
log "Configuring chronyd to sync with DC"
sed -i "s/^pool.*/server $DC_IP iburst/" /etc/chrony.conf
systemctl restart chronyd
systemctl enable chronyd
log "Time sync configured"

# 7. Join the AD domain
log "Joining domain $DOMAIN"
echo "Prompting for AD $AD_ADMIN password..."
realm join -U "$AD_ADMIN" "$DOMAIN" || { log "ERROR: Failed to join domain"; exit 1; }
log "Successfully joined $DOMAIN"

# 8. Configure SSSD
log "Configuring SSSD"
cat << EOF > /etc/sssd/sssd.conf
[sssd]
domains = $DOMAIN
config_file_version = 2
services = nss, pam

[domain/$DOMAIN]
ad_domain = $DOMAIN
krb5_realm = ${DOMAIN^^}  # Uppercase for Kerberos
realmd_tags = manages-system joined-with-adcli
cache_credentials = True
id_provider = ad
krb5_store_password_if_offline = True
default_shell = /bin/bash
ldap_id_mapping = True
use_fully_qualified_names = False  # Allows login as "username" instead of "username@msp.local"
fallback_homedir = /home/%u
access_provider = ad
EOF
chmod 600 /etc/sssd/sssd.conf
systemctl restart sssd
systemctl enable sssd
log "SSSD configured"

# 9. Test domain join
log "Verifying domain join"
realm list | grep "$DOMAIN" || { log "ERROR: Domain join verification failed"; exit 1; }

log "Testing DNS resolution"
nslookup "$DOMAIN" "$DNS" | grep "$DC_IP" || { log "ERROR: DNS resolution failed"; exit 1; }

# 10. Test AD login with Administrator
log "Testing AD login with $AD_ADMIN"
echo "You can now test login manually: ssh $AD_ADMIN@localhost"
echo "If SSH fails, ensure an AD user has a home directory created or use 'sss_ssh_authorizedkeys' for key-based auth."

# 11. Finalize
log "RHEL 9 workstation node setup completed successfully"
echo "Setup complete! Verify AD login with '$AD_ADMIN' (ssh $AD_ADMIN@localhost)."
echo "Once the RHEL 9 control node is online, add $STATIC_IP to its Ansible inventory under [remote_nodes]."
echo "Logs available at $LOGFILE"
