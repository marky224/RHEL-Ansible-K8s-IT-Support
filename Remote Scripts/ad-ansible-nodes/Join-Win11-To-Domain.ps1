# Join-Win11-To-Domain.ps1
# Automates joining a Windows 11 Pro workstation to the msp.local domain

# Set strict mode and error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Variables (customizable)
$Domain = "msp.local"
$DCIP = "192.168.0.10"
$StaticIP = "192.168.0.12"  # Next available IP; adjust as needed
$SubnetMask = "255.255.255.0"
$Gateway = "192.168.0.1"    # UniFi Express default
$DNS = "192.168.0.10"       # DC IP for DNS
$ComputerName = "WORKSTATION01"  # Desired hostname
$LogFile = "C:\ADSetup\Win11Join_Log.txt"

# Ensure log directory exists
if (-not (Test-Path "C:\ADSetup")) {
    New-Item -ItemType Directory -Path "C:\ADSetup" | Out-Null
}

# Function to log messages
function Write-Log {
    param ([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $LogFile -Append
}

Write-Log "Starting Windows 11 Pro domain join for $Domain"

# 1. Set hostname
Write-Log "Setting computer name to $ComputerName"
Rename-Computer -NewName $ComputerName -Force -Restart:$false

# 2. Configure static IP
$NetAdapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -First 1
if (-not $NetAdapter) {
    Write-Log "ERROR: No active network adapter found"
    Write-Error "No active network adapter found"
    exit 1
}
$InterfaceName = $NetAdapter.Name
Write-Log "Configuring static IP $StaticIP on $InterfaceName"
$IPConfig = Get-NetIPAddress -InterfaceAlias $InterfaceName -AddressFamily IPv4 -ErrorAction SilentlyContinue
if ($IPConfig -and $IPConfig.IPAddress -ne $StaticIP) {
    if ($IPConfig.PrefixOrigin -eq "Dhcp") {
        Write-Log "Disabling DHCP"
        Set-NetIPInterface -InterfaceAlias $InterfaceName -Dhcp Disabled
        if ($IPConfig) {
            Remove-NetIPAddress -InterfaceAlias $InterfaceName -IPAddress $IPConfig.IPAddress -Confirm:$false -ErrorAction SilentlyContinue
        }
    }
    New-NetIPAddress -InterfaceAlias $InterfaceName -IPAddress $StaticIP -PrefixLength 24 -DefaultGateway $Gateway -Verbose | Out-Null
    Set-DnsClientServerAddress -InterfaceAlias $InterfaceName -ServerAddresses $DNS -Verbose | Out-Null
    Write-Log "Static IP set: $StaticIP, Gateway: $Gateway, DNS: $DNS"
} else {
    Write-Log "IP already set to $StaticIP"
}

# 3. Prompt for AD admin password
Write-Host "=============================================================" -ForegroundColor Yellow
Write-Host "DOMAIN JOIN PASSWORD" -ForegroundColor Green
Write-Host "Enter the AD Administrator password for $Domain" -ForegroundColor Yellow
Write-Host "This is the password set during DC setup (04-Promote-DomainController.ps1)" -ForegroundColor Yellow
Write-Host "=============================================================" -ForegroundColor Yellow
$Credential = Get-Credential -UserName "MSP\Administrator" -Message "Enter AD Administrator password"

# 4. Join the domain
Write-Log "Joining $Domain"
try {
    Add-Computer -DomainName $Domain -Credential $Credential -Restart -Force -Verbose | Out-Null
    Write-Log "Successfully joined $Domain"
} catch {
    Write-Log "ERROR: Failed to join domain - $_"
    Write-Error "Failed to join domain: $_"
    exit 1
}

# 5. Post-join instructions (won’t run until reboot, so logged/displayed)
Write-Log "Domain join initiated - rebooting..."
Write-Host "Workstation will reboot to complete domain join." -ForegroundColor Green
Write-Host "After reboot, log in with MSP\Administrator or another AD user." -ForegroundColor Yellow
Write-Host "Logs available at $LogFile" -ForegroundColor Green
