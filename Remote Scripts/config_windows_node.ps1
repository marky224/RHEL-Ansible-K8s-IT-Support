# Set-StaticIP-Dynamic-Troubleshoot.ps1
# Script to dynamically configure static IP with troubleshooting

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
    Write-Host "Using interface: $InterfaceAlias"
    
    # Get current IP configuration
    $IPConfig = Get-NetIPConfiguration -InterfaceAlias $InterfaceAlias
    
    # Gather existing network parameters
    $DefaultGateway = $IPConfig.IPv4DefaultGateway.NextHop
    $DNSServers = $IPConfig.DNSServer.ServerAddresses
    $CurrentIP = Get-NetIPAddress -InterfaceAlias $InterfaceAlias -AddressFamily IPv4
    $SubnetMaskBits = $CurrentIP.PrefixLength
    
    Write-Host "Detected Settings:"
    Write-Host "Current Gateway: $DefaultGateway"
    Write-Host "DNS Servers: $DNSServers"
    Write-Host "Subnet Mask Bits: $SubnetMaskBits"
    
    # Test current gateway before proceeding
    $GatewayTest = Test-NetConnection -ComputerName $DefaultGateway -WarningAction SilentlyContinue
    if (-not $GatewayTest.PingSucceeded) {
        Write-Warning "Current gateway ($DefaultGateway) is not responding."
        $DefaultGateway = Read-Host "Please enter the correct gateway IP (or press Enter to skip)"
        if ([string]::IsNullOrEmpty($DefaultGateway)) {
            Write-Warning "No gateway specified. Proceeding without gateway."
        }
    }
    
    # Remove existing IP configuration
    Remove-NetIPAddress -InterfaceAlias $InterfaceAlias -Confirm:$false
    
    # Set new static IP address
    if ($DefaultGateway) {
        New-NetIPAddress -InterfaceAlias $InterfaceAlias `
            -IPAddress $TargetIPAddress `
            -PrefixLength $SubnetMaskBits `
            -DefaultGateway $DefaultGateway `
            -ErrorAction Stop
    } else {
        New-NetIPAddress -InterfaceAlias $InterfaceAlias `
            -IPAddress $TargetIPAddress `
            -PrefixLength $SubnetMaskBits `
            -ErrorAction Stop
    }
    
    # Configure DNS servers
    Set-DnsClientServerAddress -InterfaceAlias $InterfaceAlias `
        -ServerAddresses $DNSServers `
        -ErrorAction Stop
    
    # Verify configuration
    $NewConfig = Get-NetIPConfiguration -InterfaceAlias $InterfaceAlias
    Write-Host "New IP Configuration:" -ForegroundColor Cyan
    $NewConfig | Format-List
    
    # Test connectivity
    if ($DefaultGateway) {
        $PingTest = Test-NetConnection -ComputerName $DefaultGateway
        if ($PingTest.PingSucceeded) {
            Write-Host "Gateway ($DefaultGateway) ping successful" -ForegroundColor Green
        } else {
            Write-Warning "Gateway ping failed. Possible issues:"
            Write-Host "- Incorrect gateway IP"
            Write-Host "- Network connectivity problem"
            Write-Host "- Firewall blocking ICMP"
        }
    }
    
    # Additional connectivity test to internet
    $InternetTest = Test-NetConnection -ComputerName "8.8.8.8"
    if ($InternetTest.PingSucceeded) {
        Write-Host "Internet connectivity confirmed (8.8.8.8 reachable)" -ForegroundColor Green
    } else {
        Write-Warning "No internet connectivity"
    }
    
} catch {
    Write-Error "Configuration failed: $_"
    Write-Host "Reverting to DHCP as fallback..."
    Set-NetIPInterface -InterfaceAlias $InterfaceAlias -Dhcp Enabled
}

Write-Host "Script completed"
