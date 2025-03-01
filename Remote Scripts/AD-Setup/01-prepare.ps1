# Dynamically set config path relative to script location
$ConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "configs\dc_config.json"

# Load config
$config = Get-Content $ConfigPath | ConvertFrom-Json

# Get the active network interface dynamically
$interface = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
$interfaceName = $interface.Name

# Set static IP
New-NetIPAddress -InterfaceAlias $interfaceName -IPAddress $config.StaticIP -PrefixLength $config.PrefixLength

# Set DNS servers
Set-DnsClientServerAddress -InterfaceAlias $interfaceName -ServerAddresses $config.DNSServers

# Rename computer
Rename-Computer -NewName $config.Hostname -Force -Restart
