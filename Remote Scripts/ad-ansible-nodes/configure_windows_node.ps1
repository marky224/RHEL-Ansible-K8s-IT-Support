# Script to configure Windows 11 Pro as a remote node
# Run as Administrator

# Variables
$ComputerName = "w11pro-wsXX"
$IPAddress = "192.168.0.136"
$SubnetMask = "255.255.255.0"  # /24
$PreferredDNS = "8.8.8.8"
$AlternateDNS = "8.8.4.4"

# Step 1: Detect the default gateway
$Gateway = (Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Select-Object -First 1).NextHop
if (-not $Gateway) {
    Write-Host "Could not detect default gateway. Using fallback: 192.168.0.1"
    $Gateway = "192.168.0.1"  # Fallback if detection fails
}
Write-Host "Detected Default Gateway: $Gateway"

# Step 2: Detect the active network interface
$Interface = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
if (-not $Interface) {
    Write-Host "No active network adapter found. Please connect to a network and rerun."
    exit
}
Write-Host "Detected Network Interface: $($Interface.Name)"

# Step 3: Set static IP address, subnet mask, and reapply detected gateway
New-NetIPAddress -InterfaceAlias $Interface.Name -IPAddress $IPAddress -PrefixLength 24 -DefaultGateway $Gateway

# Step 4: Set DNS servers
Set-DnsClientServerAddress -InterfaceAlias $Interface.Name -ServerAddresses ($PreferredDNS, $AlternateDNS)

# Step 5: Install OpenSSH Server (for Ansible via SSH)
if (-not (Get-WindowsCapability -Online | Where-Object { $_.Name -like "OpenSSH.Server*" -and $_.State -eq "Installed" })) {
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
}

# Start and configure OpenSSH service
Start-Service sshd
Set-Service sshd -StartupType Automatic

# Step 6: Configure Windows Firewall to allow SSH (port 22)
New-NetFirewallRule -Name "Allow SSH" -DisplayName "Allow SSH" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22

# Step 7: Verify configuration
Write-Host "Windows 11 Pro configuration complete."
Write-Host "IP Address: $IPAddress"
Write-Host "Subnet Mask: $SubnetMask"
Write-Host "Default Gateway: $Gateway"
Write-Host "DNS Servers: $PreferredDNS, $AlternateDNS"
Write-Host "SSH Server Status: $(Get-Service sshd | Select-Object -ExpandProperty Status)"

# Step 8: Rename the computer and restart (at the end)
Rename-Computer -NewName $ComputerName -Force
Write-Host "Computer renamed to $ComputerName. Restarting in 5 seconds..."
Start-Sleep -Seconds 5
Restart-Computer -Force
