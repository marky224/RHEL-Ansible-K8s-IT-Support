# Script: configure_windows_node.ps1
# Run as Administrator (elevated context required)

# Check if running as admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Error: This script must be run as Administrator." -ForegroundColor Red
    Exit 1
}

# Variables
$HostName = "w11pro-wsXX"
$NodeIP = "192.168.0.136"
$DC_IP = "192.168.0.10"  # Confirmed AD DC IP

# Set hostname
Rename-Computer -NewName $HostName -Force -Restart

# Set static IP and DNS (no default gateway specified)
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress $NodeIP -PrefixLength 24
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses $DC_IP

# Install OpenSSH Server (run this part after reboot manually or via a scheduled task)
Install-WindowsFeature -Name OpenSSH-Server
Set-Service -Name sshd -StartupType 'Automatic'
Start-Service -Name sshd

# Allow SSH through Windows Firewall
New-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -DisplayName "OpenSSH Server (sshd)" `
    -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22

Write-Host "Windows node configured. Reboot required before SSH is fully active."
