# Set-StaticIP-Dynamic.ps1
# Script to dynamically configure static IP on Windows 11 Pro VM

# Target IP address
$TargetIPAddress = "192.168.10.136"

try {
    # Get the active network interface (assumes one primary connected adapter)
    $Interface = Get-NetAdapter | 
        Where-Object { $_.Status -eq "Up" -and $_.Name -like "Ethernet*" } | 
        Select-Object -First 1
    
    if (-not $Interface) {
        throw "No active Ethernet adapter found"
    }
    
    $InterfaceAlias = $Interface.Name
    
    # Get current IP configuration
    $IPConfig = Get-NetIPConfiguration -InterfaceAlias $InterfaceAlias
    
    # Gather existing network parameters
    $DefaultGateway = $IPConfig.IPv4DefaultGateway.NextHop
    $DNSServers = $IPConfig.DNSServer.ServerAddresses
    $CurrentIP = Get-NetIPAddress -InterfaceAlias $InterfaceAlias -AddressFamily IPv4
    $SubnetMaskBits = $CurrentIP.PrefixLength
    
    # Remove existing IP configuration
    Remove-NetIPAddress -InterfaceAlias $InterfaceAlias -Confirm:$false
    
    # Set new static IP address with gathered parameters
    New-NetIPAddress -InterfaceAlias $InterfaceAlias `
        -IPAddress $TargetIPAddress `
        -PrefixLength $SubnetMaskBits `
        -DefaultGateway $DefaultGateway `
        -ErrorAction Stop
    
    # Configure DNS servers
    Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias `
        -ServerAddresses $DNSServers `
        -ErrorAction Stop
    
    # Verify configuration
    $NewConfig = Get-NetIPConfiguration -InterfaceAlias $InterfaceAlias
    Write-Host "New IP Configuration:"
    $NewConfig | Format-List
    
    # Test connectivity
    $PingTest = Test-NetConnection -ComputerName $DefaultGateway
    if ($PingTest.PingSucceeded) {
        Write-Host "Network connectivity confirmed" -ForegroundColor Green
    } else {
        Write-Warning "Gateway ping failed - please check network configuration"
    }
    
} catch {
    Write-Error "Configuration failed: $_"
    Write-Host "Reverting to DHCP as fallback..."
    Set-NetIPInterface -InterfaceAlias $InterfaceAlias -Dhcp Enabled
}

Write-Host "Script completed"
