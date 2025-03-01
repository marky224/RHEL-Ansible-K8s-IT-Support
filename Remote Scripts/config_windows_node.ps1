# Set-StaticIP-Dynamic-SSH.ps1
# Script to configure static IP and enable SSH on Windows 11 Pro VM

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
    Set-DnsClientDohServerAddress -ServerAddress "8.8.8.8" `
        -DohTemplate "https://dns.google/dns-query" `
        -AutoUpgrade $true `
        -ErrorAction SilentlyContinue
    Set-DnsClientDohServerAddress -ServerAddress "8.8.4.4" `
        -DohTemplate "https://dns.google/dns-query" `
        -AutoUpgrade $true `
        -ErrorAction SilentlyContinue
    
    # Enable SSH Server
    # Install OpenSSH Server if not already installed
    if (-not (Get-WindowsCapability -Online | Where-Object { $_.Name -like "OpenSSH.Server*" -and $_.State -eq "Installed" })) {
        Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 -ErrorAction Stop
    }
    
    # Start and configure SSH service
    Set-Service -Name sshd -StartupType Automatic -ErrorAction Stop
    Start-Service -Name sshd -ErrorAction Stop
    
    # Configure firewall rule for SSH (port 22)
    $FirewallRule = Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue
    if (-not $FirewallRule) {
        New-NetFirewallRule -Name "OpenSSH-Server-In-TCP" `
            -DisplayName "OpenSSH Server (sshd)" `
            -Enabled True `
            -Direction Inbound `
            -Protocol TCP `
            -Action Allow `
            -LocalPort 22 `
            -ErrorAction Stop
    }
    
    # Verify configuration
    $NewConfig = Get-NetIPConfiguration -InterfaceAlias $InterfaceAlias
    Write-Host "New IP Configuration:"
    $NewConfig | Format-List
    
    # Verify SSH service
    $SSHStatus = Get-Service -Name sshd
    Write-Host "SSH Service Status: $($SSHStatus.Status)" -ForegroundColor Green
    
    Write-Host "Network and SSH configuration applied successfully" -ForegroundColor Green
    
} catch {
    Write-Error "Configuration failed: $_"
    Write-Host "Reverting to DHCP as fallback..."
    Set-NetIPInterface -InterfaceAlias $InterfaceAlias -Dhcp Enabled
}

Write-Host "Script completed"
