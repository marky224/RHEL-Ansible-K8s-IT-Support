# windows_connect.ps1
# Configures Windows 11 Pro at 192.168.10.135 to connect to Ansible control node at 192.168.10.100 via WinRM over HTTPS

param (
    [string]$ControlNodeIP = "192.168.10.100",  # Ansible control node IP
    [string]$TargetIP = "192.168.10.135",       # Target Windows PC static IP
    [string]$Username,                          # Windows admin user (prompted if not provided)
    [string]$Password,                          # Windows admin password (prompted if not provided)
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

# Prompt for Username and Password if not provided
if (-not $Username) {
    $Username = Read-Host "Enter Windows admin username"
    if (-not $Username) {
        Write-Error "Username cannot be empty"
        Add-Content -Path $logFile -Value "$(Get-Date) - Error: Username not provided"
        exit 1
    }
}
Add-Content -Path $logFile -Value "$(Get-Date) - Username set to $Username"

if (-not $Password) {
    $securePassword = Read-Host "Enter Windows admin password" -AsSecureString
    $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePassword))
    if (-not $Password) {
        Write-Error "Password cannot be empty"
        Add-Content -Path $logFile -Value "$(Get-Date) - Error: Password not provided"
        exit 1
    }
}
Add-Content -Path $logFile -Value "$(Get-Date) - Password provided (masked in logs)"

# Get active network interface dynamically
Write-Host "Detecting active network interface..." -Verbose
Add-Content -Path $logFile -Value "$(Get-Date) - Detecting network interface"
try {
    $interface = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.InterfaceDescription -notlike "*Virtual*" } | Select-Object -First 1
    if (-not $interface) {
        throw "No active physical network interface found"
    }
    $interfaceName = $interface.Name
    Add-Content -Path $logFile -Value "$(Get-Date) - Interface detected: $interfaceName"
} catch {
    Write-Error "Failed to detect network interface: $_"
    Add-Content -Path $logFile -Value "$(Get-Date) - Error: Interface detection failed: $_"
    exit 1
}

# Set static IP with retry logic
Write-Host "Configuring static IP $TargetIP on $interfaceName..." -Verbose
Add-Content -Path $logFile -Value "$(Get-Date) - Configuring static IP $TargetIP"
$currentIP = (Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias $interfaceName -ErrorAction SilentlyContinue).IPAddress
for ($attempt = 1; $attempt -le 3; $attempt++) {
    try {
        if ($currentIP -ne $TargetIP) {
            if ($currentIP) {
                Remove-NetIPAddress -IPAddress $currentIP -InterfaceAlias $interfaceName -Confirm:$false -ErrorAction Stop
            }
            New-NetIPAddress -InterfaceAlias $interfaceName -IPAddress $TargetIP -PrefixLength 24 -DefaultGateway "192.168.10.1" -ErrorAction Stop | Out-Null
            Set-DnsClientServerAddress -InterfaceAlias $interfaceName -ServerAddresses "192.168.10.1" -ErrorAction Stop
        }
        Add-Content -Path $logFile -Value "$(Get-Date) - Static IP set to $TargetIP"
        break
    } catch {
        Write-Warning "IP configuration attempt $attempt failed: $_"
        Add-Content -Path $logFile -Value "$(Get-Date) - Warning: IP configuration attempt $attempt failed: $_"
        if ($attempt -eq 3) {
            Write-Error "Failed to set static IP after 3 attempts: $_"
            Add-Content -Path $logFile -Value "$(Get-Date) - Error: Static IP configuration failed after 3 attempts: $_"
            exit 1
        }
        Start-Sleep -Seconds 5
    }
}

# Generate self-signed certificate for WinRM HTTPS if not present
Write-Host "Generating self-signed certificate for WinRM HTTPS..." -Verbose
Add-Content -Path $logFile -Value "$(Get-Date) - Generating self-signed certificate"
$certThumbprint = (Get-ChildItem -Path Cert:\LocalMachine\My | Where-Object { $_.Subject -eq "CN=AnsibleWinRM" }).Thumbprint
if (-not $certThumbprint) {
    try {
        $cert = New-SelfSignedCertificate -CertStoreLocation Cert:\LocalMachine\My -DnsName $env:COMPUTERNAME -NotAfter (Get-Date).AddYears(5) -Subject "CN=AnsibleWinRM" -ErrorAction Stop
        $certThumbprint = $cert.Thumbprint
        Add-Content -Path $logFile -Value "$(Get-Date) - Self-signed certificate generated: $certThumbprint"
    } catch {
        Write-Error "Failed to generate self-signed certificate: $_"
        Add-Content -Path $logFile -Value "$(Get-Date) - Error: Certificate generation failed: $_"
        exit 1
    }
}

# Configure WinRM for HTTPS
Write-Host "Configuring WinRM for HTTPS..." -Verbose
Add-Content -Path $logFile -Value "$(Get-Date) - Configuring WinRM for HTTPS"
try {
    Enable-PSRemoting -Force -ErrorAction Stop
    Set-Item -Path WSMan:\localhost\Client\TrustedHosts -Value $ControlNodeIP -Force -ErrorAction Stop
    New-Item -Path WSMan:\localhost\Listener -Address * -Transport HTTPS -CertificateThumbprint $certThumbprint -Force -ErrorAction Stop | Out-Null
    Add-Content -Path $logFile -Value "$(Get-Date) - WinRM HTTPS listener configured"
} catch {
    Write-Error "Failed to configure WinRM HTTPS: $_"
    Add-Content -Path $logFile -Value "$(Get-Date) - Error: WinRM HTTPS configuration failed: $_"
    exit 1
}

# Open WinRM HTTPS port (5986) in firewall
Write-Host "Opening WinRM HTTPS port (5986) in firewall..." -Verbose
Add-Content -Path $logFile -Value "$(Get-Date) - Opening WinRM HTTPS port"
try {
    New-NetFirewallRule -Name "WinRM-HTTPS" -DisplayName "WinRM HTTPS" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 5986 -ErrorAction Stop
} catch {
    Write-Error "Failed to configure firewall for WinRM HTTPS: $_"
    Add-Content -Path $logFile -Value "$(Get-Date) - Error: Firewall configuration for HTTPS failed: $_"
    exit 1
}
Add-Content -Path $logFile -Value "$(Get-Date) - Firewall rule added for WinRM HTTPS"

# Send check-in to control node with retry logic
Write-Host "Sending check-in to control node..." -Verbose
Add-Content -Path $logFile -Value "$(Get-Date) - Sending check-in"
$hostname = $env:COMPUTERNAME
$body = "hostname=$hostname&ip=$TargetIP&os=windows11"
$checkinUrl = "https://$ControlNodeIP:$CheckinPort/checkin"
for ($i = 1; $i -le 3; $i++) {
    try {
        Invoke-WebRequest -Uri $checkinUrl -Method POST -Body $body -UseBasicParsing -SkipCertificateCheck -ErrorAction Stop
        Add-Content -Path $logFile -Value "$(Get-Date) - Check-in successful on attempt $i"
        break
    } catch {
        Write-Warning "Check-in attempt $i failed: $_"
        Add-Content -Path $logFile -Value "$(Get-Date) - Check-in attempt $i failed: $_"
        if ($i -eq 3) {
            Write-Error "Failed to send check-in after 3 attempts: $_"
            Add-Content -Path $logFile -Value "$(Get-Date) - Error: Check-in failed after 3 attempts: $_"
            exit 1
        }
        Start-Sleep -Seconds 5
    }
}

# Completion message
Write-Host "Windows 11 Pro PC at $TargetIP configured for Ansible control at $ControlNodeIP over HTTPS" -Verbose
Add-Content -Path $logFile -Value "$(Get-Date) - Configuration completed successfully"
