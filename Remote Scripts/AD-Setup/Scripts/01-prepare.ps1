# Purpose: Prepares the server with static IP, hostname, and updates
param (
    [string]$ConfigPath = "..\configs\dc_config.json"
)

# Load config
$config = Get-Content $ConfigPath | ConvertFrom-Json

# Set static IP
New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress $config.StaticIP -PrefixLength 24 -DefaultGateway $config.Gateway
Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses $config.DnsServer

# Set hostname
Rename-Computer -NewName $config.Hostname -Force -Restart

# Install updates
Install-Module -Name PSWindowsUpdate -Force -SkipPublisherCheck
Import-Module PSWindowsUpdate
Get-WindowsUpdate -AcceptAll -Install -AutoReboot
