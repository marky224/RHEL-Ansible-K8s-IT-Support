<#
.SYNOPSIS
    Configures a Windows 11 Pro machine as a remote node with a static IP and custom hostname.
    Must be run with administrative privileges.

.DESCRIPTION
    This script automates the configuration of a Windows 11 Pro workstation as a remote node.
    It sets a static IP address, configures DNS servers, renames the computer, and restarts the system.
    User input is required for the workstation number (01-99) and IP address last octet (30-90).
    The script includes validation for inputs and network adapter detection.

.PREREQUISITES
    - Run as Administrator.
    - Active network connection.

.NOTES
    - IP address format: 192.168.0.XX (where XX is the user-defined last octet).
    - Computer name format: w11pro-wsXX (where XX is the user-defined workstation number).
    - Subnet mask is hardcoded to 255.255.255.0 (/24).
    - Default gateway is auto-detected with a fallback to 192.168.0.1.
    - DNS servers are set to 192.168.0.10 (preferred) and 8.8.8.8 (alternate).
#>

# Check if running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Error: This script must be run as Administrator." -ForegroundColor Red
    Exit 1
}

# Prompt for workstation number (01-99) with validation
do {
    $WorkstationNum = Read-Host "Enter workstation number (01-99)"
    if ($WorkstationNum -match '^\d{2}$' -and [int]$WorkstationNum -ge 1 -and [int]$WorkstationNum -le 99) {
        $validNum = $true
    } else {
        Write-Host "Invalid input. Please enter a two-digit number between 01 and 99." -ForegroundColor Yellow
        $validNum = $false
    }
} while (-not $validNum)

# Prompt for IP address last octet (30-90) with validation
do {
    $IPLastOctet = Read-Host "Enter IP address last octet (30-90)"
    if ($IPLastOctet -match '^\d+$' -and [int]$IPLastOctet -ge 30 -and [int]$IPLastOctet -le 90) {
        $validIP = $true
    } else {
        Write-Host "Invalid input. Please enter a number between 30 and 90." -ForegroundColor Yellow
        $validIP = $false
    }
} while (-not $validIP)

# Define variables with user input
$ComputerName = "w11pro-ws$WorkstationNum"  # e.g., w11pro-ws01
$IPAddress = "192.168.0.$IPLastOctet"       # e.g., 192.168.0.30
$SubnetMask = "255.255.255.0"               # /24
$PreferredDNS = "192.168.0.10"              # Preferred DNS server
$AlternateDNS = "8.8.8.8"                   # Alternate DNS server (Google Public DNS)

# Step 1: Detect the default gateway
$Gateway = (Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Select-Object -First 1).NextHop
if (-not $Gateway) {
    Write-Host "Could not detect default gateway. Using fallback: 192.168.0.1" -ForegroundColor Yellow
    $Gateway = "192.168.0.1"  # Fallback if detection fails
}
Write-Host "Detected Default Gateway: $Gateway"

# Step 2: Detect the active network interface
$Interface = Get-NetAdapter | Where-Object { $_.Status -eq "Up" }
if (-not $Interface) {
    Write-Host "No active network adapter found. Please connect to a network and rerun." -ForegroundColor Red
    Exit 1
}
Write-Host "Detected Network Interface: $($Interface.Name)"

# Step 3: Set static IP address, subnet mask, and reapply detected gateway
New-NetIPAddress -InterfaceAlias $Interface.Name -IPAddress $IPAddress -PrefixLength 24 -DefaultGateway $Gateway

# Step 4: Set DNS servers
Set-DnsClientServerAddress -InterfaceAlias $Interface.Name -ServerAddresses ($PreferredDNS, $AlternateDNS)

# Step 5: Verify configuration
Write-Host "Windows 11 Pro configuration complete." -ForegroundColor Green
Write-Host "IP Address: $IPAddress"
Write-Host "Subnet Mask: $SubnetMask"
Write-Host "Default Gateway: $Gateway"
Write-Host "DNS Servers: $PreferredDNS, $AlternateDNS"

# Step 6: Rename the computer and restart
Rename-Computer -NewName $ComputerName -Force
Write-Host "Computer renamed to $ComputerName. Restarting in 5 seconds..." -ForegroundColor Green
Start-Sleep -Seconds 5
Restart-Computer -Force
