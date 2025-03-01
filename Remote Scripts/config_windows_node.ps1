# PowerShell script to configure Windows 11 Pro worker with static IP and enable SSH
# Run as Administrator

# Dynamically detect the first active non-loopback interface
$interface = (Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.Name -notlike "*Loopback*" } | Select-Object -First 1).Name
if (-not $interface) {
    Write-Output "Error: No active non-loopback network interface found."
    exit 1
}

# Gather current info
Write-Output "Current Configuration:"
Write-Output "Hostname: $env:COMPUTERNAME"
Write-Output "IP: $((Get-NetIPAddress -InterfaceAlias $interface -AddressFamily IPv4).IPAddress)"
Write-Output "Gateway: $((Get-NetRoute -DestinationPrefix '0.0.0.0/0' | Where-Object { $_.InterfaceAlias -eq $interface }).NextHop)"
Write-Output "DNS Servers: $((Get-DnsClientServerAddress -InterfaceAlias $interface -AddressFamily IPv4).ServerAddresses -join ', ')"
Write-Output "OS: $([System.Environment]::OSVersion.VersionString)"
Write-Output "User: $env:USERNAME"

# Set static IP to 192.168.10.116 with local DNS
Write-Output "Setting static IP to 192.168.10.116 on interface $interface with DNS 192.168.10.1..."
New-NetIPAddress -InterfaceAlias $interface -IPAddress 192.168.10.116 -PrefixLength 24 -DefaultGateway 192.168.10.1
Set-DnsClientServerAddress -InterfaceAlias $interface -ServerAddresses "192.168.10.1"

# Enable OpenSSH Server
Write-Output "Enabling OpenSSH Server for Ansible connectivity..."
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Start-Service sshd
Set-Service sshd -StartupType Automatic

# Configure firewall for SSH (port 22)
Write-Output "Configuring firewall to allow SSH from 192.168.10.0/24..."
New-NetFirewallRule -DisplayName "Allow SSH" -Direction Inbound -Protocol TCP -LocalPort 22 -Action Allow -Profile Any -RemoteAddress 192.168.10.0/24

# Verify new configuration
Write-Output "New Configuration:"
Write-Output "Hostname: $env:COMPUTERNAME"
Write-Output "IP: $((Get-NetIPAddress -InterfaceAlias $interface -AddressFamily IPv4).IPAddress)"
Write-Output "Gateway: $((Get-NetRoute -DestinationPrefix '0.0.0.0/0' | Where-Object { $_.InterfaceAlias -eq $interface }).NextHop)"
Write-Output "DNS Servers: $((Get-DnsClientServerAddress -InterfaceAlias $interface -AddressFamily IPv4).ServerAddresses -join ', ')"
Write-Output "OS: $([System.Environment]::OSVersion.VersionString)"
Write-Output "User: $env:USERNAME"
Write-Output "SSH Port: 22 (check with 'netstat -an | findstr :22')"
Write-Output "Static IP set to 192.168.10.116 and SSH enabled for Ansible connection."
