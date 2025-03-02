# Script: configure_windows_node.ps1
# Run as Administrator

# Variables
$DomainName = "internal.nexlify.nxl"
$HostName = "w11pro-ws01"
$NodeIP = "192.168.0.136"
$Gateway = "192.168.0.1"
$AdminUser = Read-Host "Enter AD admin username (e.g., Administrator)"
$AdminPass = Read-Host "Enter AD admin password" -AsSecureString
$Credential = New-Object System.Management.Automation.PSCredential ($AdminUser, $AdminPass)

# Set hostname
Rename-Computer -NewName $HostName -Force -Restart

# Set static IP and DNS (assuming AD DC is at 192.168.0.10, adjust as needed)
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress $NodeIP -PrefixLength 24 -DefaultGateway $Gateway
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses "192.168.0.10"

# Join the domain
Add-Computer -DomainName $DomainName -Credential $Credential -Restart -Force

# Install OpenSSH Server (run this part after reboot manually or via a scheduled task)
Install-WindowsFeature -Name OpenSSH-Server
Set-Service -Name sshd -StartupType 'Automatic'
Start-Service -Name sshd

# Allow SSH through Windows Firewall
New-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -DisplayName "OpenSSH Server (sshd)" `
    -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22

Write-Host "Windows node configured. Reboot required before SSH is fully active."
