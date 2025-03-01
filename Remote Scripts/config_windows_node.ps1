# Set-StaticIP-Dynamic.ps1
# Updated script with fixed DNS and optional DoH support

# Target IP address
$TargetIPAddress = "192.168.10.136"

try {
    # Get the active network interface
    $Interface = Get-NetAdapter | 
        Where-Object { $_.Status -eq "Up" -and $_.Name -like "Ethernet*" } | 
        Select-Object -First 1
    
    if (-not $Interface) {
        throw "No active Ethernet adapter found"
    }
    
    $InterfaceAlias = $Interface.Name
    
    # Get current IP configuration
    $IPConfig = Get-NetIPConfiguration -InterfaceAlias $InterfaceAlias
    
    # Gather existing network parameters (except DNS)
    $DefaultGateway = $IPConfig.IPv4DefaultGateway.NextHop
    $CurrentIP = Get-NetIPAddress -InterfaceAlias $InterfaceAlias -AddressFamily IPv4
    $SubnetMaskBits = $CurrentIP.PrefixLength
    
    # Define DNS servers (Google's public DNS)
    $DNSServers = "8.8.8.8", "8.8.4.4"
    
    # Remove existing IP configuration
    Remove-NetIPAddress -InterfaceAlias $InterfaceAlias -Confirm:$false
    
    # Set new static IP address
    New-NetIPAddress -InterfaceAlias $InterfaceAlias `
        -IPAddress $TargetIPAddress `
        -PrefixLength $SubnetMaskBits `
        -DefaultGateway $DefaultGateway `
        -ErrorAction Stop
    
    # Configure DNS servers
    Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias `
        -ServerAddresses $DNSServers `
        -ErrorAction Stop
    
    # Optional: Enable DNS over HTTPS (DoH) for encryption
    # Requires Windows 11 22H2 or later
    Set-DnsClientDohServerAddress -ServerAddress "8.8.8.8" `
        -DohTemplate "https://dns.google/dns-query" `
        -AutoUpgrade $true `
        -ErrorAction SilentlyContinue
    Set-DnsClientDohServerAddress -ServerAddress "8.8.4.4" `
        -DohTemplate "https://dns.google/dns-query" `
        -AutoUpgrade $true `
        -ErrorAction SilentlyContinue
    
    # Verify configuration
    $NewConfig = Get-NetIPConfiguration -InterfaceAlias $InterfaceAlias
    Write-Host "New IP Configuration:"
    $NewConfig | Format-List
    
    # Test connectivity
    $PingTest = Test-NetConnection -ComputerName $DefaultGateway
    if ($PingTest.PingSucceeded) {
        Write-Host "Gateway connectivity confirmed" -ForegroundColor Green
    } else {
        Write-Warning "Gateway ping failed - please check network configuration"
    }
    
    # Test DNS
    $DNSTest = Test-NetConnection -ComputerName "google.com"
    if ($DNSTest.PingSucceeded) {
        Write-Host "DNS resolution confirmed" -ForegroundColor Green
    } else {
        Write-Warning "DNS resolution failed - please check DNS settings"
    }
    
} catch {
    Write-Error "Configuration failed: $_"
    Write-Host "Reverting to DHCP as fallback..."
    Set-NetIPInterface -InterfaceAlias $InterfaceAlias -Dhcp Enabled
}

Write-Host "Script completed"
