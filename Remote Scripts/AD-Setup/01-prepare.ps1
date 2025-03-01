# Dynamically set config path relative to script location
$ConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "configs\dc_config.json"

# Load config
$config = Get-Content $ConfigPath | ConvertFrom-Json

# Extract DC config from nested structure (first site, first DC)
$dcConfig = $config.Sites[0].DomainControllers[0]
$networkConfig = $dcConfig.Network

# Get the active network interface dynamically
$interface = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
$interfaceName = $interface.Name

# Get current IP config dynamically
$currentIpConfig = Get-NetIPAddress -InterfaceAlias $interfaceName -AddressFamily IPv4 -ErrorAction SilentlyContinue
$prefixLength = $currentIpConfig.PrefixLength
$currentIpAddress = $currentIpConfig.IPAddress
$currentHostname = $env:COMPUTERNAME
$gateway = (Get-NetRoute | Where-Object { $_.DestinationPrefix -eq '0.0.0.0/0' -and $_.InterfaceAlias -eq $interfaceName }).NextHop

# Get current DNS server dynamically (first server only)
$currentDnsServers = (Get-DnsClientServerAddress -InterfaceAlias $interfaceName -AddressFamily IPv4).ServerAddresses[0]

# Set static IP if not already correct, reapplying current gateway, prefix, and DNS
if ($currentIpAddress -ne $networkConfig.StaticIP) {
    Write-Host "Setting new IP address, preserving current gateway and settings..."
    # Remove existing IP to avoid conflicts
    Remove-NetIPAddress -InterfaceAlias $interfaceName -IPAddress $currentIpAddress -Confirm:$false -ErrorAction SilentlyContinue
    # Set new IP with current gateway and prefix
    New-NetIPAddress -InterfaceAlias $interfaceName -IPAddress $networkConfig.StaticIP -PrefixLength $prefixLength -DefaultGateway $gateway
    # Reapply current DNS servers
    Set-DnsClientServerAddress -InterfaceAlias $interfaceName -ServerAddresses $currentDnsServers
} else {
    Write-Host "IP already set to $($networkConfig.StaticIP), checking gateway and DNS..."
    # Ensure gateway is set if missing
    if (-not (Get-NetRoute -DestinationPrefix "0.0.0.0/0" -InterfaceAlias $interfaceName -ErrorAction SilentlyContinue)) {
        Write-Host "Gateway missing, applying $gateway..."
        New-NetIPAddress -InterfaceAlias $interfaceName -IPAddress $networkConfig.StaticIP -PrefixLength $prefixLength -DefaultGateway $gateway -SkipAsSource $false
    }
    # Ensure DNS is set
    $existingDns = (Get-DnsClientServerAddress -InterfaceAlias $interfaceName -AddressFamily IPv4).ServerAddresses[0]
    if ($existingDns -ne $currentDnsServers) {
        Write-Host "DNS mismatch, reapplying $currentDnsServers..."
        Set-DnsClientServerAddress -InterfaceAlias $interfaceName -ServerAddresses $currentDnsServers
    } else {
        Write-Host "Gateway and DNS already set, no changes needed."
    }
}

# Rename computer
Rename-Computer -NewName $dcConfig.Hostname -Force -Restart
