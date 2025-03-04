# Script: configure_windows_node.ps1
# Run as Administrator (elevated context required)

# Check if running as admin
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

# Variables
$HostName = "w11pro-ws$WorkstationNum"
$NodeIP = "192.168.0.$IPLastOctet"

# Get the active network adapter name
$Adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.InterfaceDescription -notlike "*Virtual*" } | Select-Object -First 1
if (-not $Adapter) {
    Write-Host "Error: No active network adapter found." -ForegroundColor Red
    Exit 1
}
$InterfaceAlias = $Adapter.Name

Write-Host "Using network adapter: $InterfaceAlias"
Write-Host "Configuring as: $HostName with IP: $NodeIP"

# Set static IP (no default gateway or DNS specified)
New-NetIPAddress -InterfaceAlias $InterfaceAlias -IPAddress $NodeIP -PrefixLength 24
Write-Host "Windows node IP configured."

# Set hostname
Rename-Computer -NewName $HostName -Force -Restart
