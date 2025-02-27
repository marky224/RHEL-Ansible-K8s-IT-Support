# windows_connect.ps1
# Configures Windows 11 Pro remote PC to connect to Ansible control node at 192.168.10.100 via WinRM

param (
    [string]$ControlNodeIP = "192.168.10.100",  # Ansible control node IP
    [string]$TargetIP = "",                     # Target Windows PC IP (customize when known)
    [string]$Username = "admin",                # Windows admin user (customize as needed)
    [string]$Password = "P@ssw0rd123",          # Windows admin password (customize/secure)
    [int]$CheckinPort = 8080                    # Port for check-in listener
)

# Setup logging
$logFile = "C:\ansible_connect.log"
if (-not (Test-Path $logFile)) {
    try {
        New-Item -Path $logFile -ItemType File -Force -ErrorAction Stop | Out-Null
    } catch {
        Write-Error "Failed to create log file at $logFile : $_"
        exit 1
    }
}
Add-Content -Path $logFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Starting Windows 11 configuration"

# Check if running as administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Please run as Administrator"
    Add-Content -Path $logFile -Value "$(Get-Date) - Error: Script must run as Administrator"
    exit 1
}
Add-Content -Path $logFile -Value "$(Get-Date) - Administrator privileges confirmed"

# Validate target IP (if provided)
if ($TargetIP) {
    $currentIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -like '*Ethernet*' }).IPAddress
    if ($currentIP -ne $TargetIP) {
        Write-Error "Script intended for $TargetIP, but running on $currentIP"
        Add-Content -Path $logFile -Value "$(Get-Date) - Error: IP mismatch: expected $TargetIP, got $currentIP"
        exit 1
    }
    Add-Content -Path $logFile -Value "$(Get-Date) - IP validated: $currentIP"
} else {
    Add-Content -Path $logFile -Value "$(Get-Date) - Warning: No target IP specified; running on current machine"
}

# Configure WinRM
Write-Host "Configuring WinRM..." -Verbose
Add-Content -Path $logFile -Value "$(Get-Date) - Configuring WinRM"
try {
    Enable-PSRemoting -Force -ErrorAction Stop
    Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value $ControlNodeIP -Force -ErrorAction Stop
    # Use HTTPS in production; basic auth for testing
    winrm set winrm/config/service '@{AllowUnencrypted="false"}' -ErrorAction Stop
    winrm set winrm/config/service/auth '@{Basic="true"}' -ErrorAction Stop
} catch {
    Write-Error "Failed to configure WinRM: $_"
    Add-Content -Path $logFile -Value "$(Get-Date) - Error: WinRM configuration failed: $_"
    exit 1
}
Add-Content -Path $logFile -Value "$(Get-Date) - WinRM configured successfully"

# Open WinRM port in firewall
Write-Host "Opening WinRM port (5985) in firewall..." -Verbose
Add-Content -Path $logFile -Value "$(Get-Date) - Opening WinRM port"
try {
    New-NetFirewallRule -Name "WinRM" -DisplayName "WinRM" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 5985 -ErrorAction Stop
} catch {
    Write-Error "Failed to configure firewall: $_"
    Add-Content -Path $logFile -Value "$(Get-Date) - Error: Firewall configuration failed: $_"
    exit 1
}
Add-Content -Path $logFile -Value "$(Get-Date) - Firewall rule added for WinRM"

# Send check-in to control node with retry logic
Write-Host "Sending check-in to control node..." -Verbose
Add-Content -Path $logFile -Value "$(Get-Date) - Sending check-in"
$hostname = $env:COMPUTERNAME
$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -like '*Ethernet*' }).IPAddress
$body = "hostname=$hostname&ip=$ip&os=windows11"
$checkinUrl = "https://$ControlNodeIP:$CheckinPort/checkin"
for ($i = 1; $i -le 3; $i++) {
    try {
        # Using --insecure for self-signed cert; replace with proper cert in production
        Invoke-WebRequest -Uri $checkinUrl -Method POST -Body $body -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
        Add-Content -Path $logFile -Value "$(Get-Date) - Check-in successful on attempt $i"
        break
    } catch {
        Write-Warning "Check-in attempt $i failed: $_"
        Add-Content -Path $logFile -Value "$(Get-Date) - Check-in attempt $i failed: $_"
        if ($i -eq 3) {
            Write-Error "Failed to send check-in after 3 attempts"
            Add-Content -Path $logFile -Value "$(Get-Date) - Error: Check-in failed after 3 attempts"
            exit 1
        }
        Start-Sleep -Seconds 5
    }
}

# Completion message
Write-Host "Windows 11 Pro PC configured for Ansible control at $ControlNodeIP" -Verbose
Add-Content -Path $logFile -Value "$(Get-Date) - Configuration completed successfully"
