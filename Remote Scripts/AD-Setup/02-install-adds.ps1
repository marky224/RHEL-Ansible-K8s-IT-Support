# 02-install-adds.ps1
# Script to install and configure Active Directory Domain Services
$ConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "configs\dc_config.json"
$logFile = "C:\Users\marky\AC-DC\Configuration\ADSetup.log"

# Function to log messages
function Write-Log {
    param ($message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $message" | Out-File -FilePath $logFile -Append
    Write-Host $message
}

# Verify config file exists
if (-not (Test-Path $ConfigPath)) {
    Write-Error "Config file not found at $ConfigPath. Please ensure dc_config.json exists."
    Write-Log "ERROR: Config file not found at $ConfigPath."
    exit 1
}

# Load config
Write-Log "Loading config from $ConfigPath..."
$config = Get-Content $ConfigPath | ConvertFrom-Json

# Extract domain settings
$domainName = $config.DomainName          # "tech.nexlify.nxl"
$netbiosName = $config.NetbiosName        # "NXL"
$forestMode = $config.ForestMode          # "Win2025"
$domainMode = $config.DomainMode          # "Win2025"
Write-Log "Domain settings: Name=$domainName, NetBIOS=$netbiosName, ForestMode=$forestMode, DomainMode=$domainMode"

# Check if local 'Administrator' account exists
$adminAccount = Get-LocalUser -Name "Administrator" -ErrorAction SilentlyContinue
if (-not $adminAccount) {
    Write-Host "Local 'Administrator' account not found. Creating it now..."
    Write-Log "Creating 'Administrator' account..."
    $password = Read-Host -Prompt "Enter a strong password for the 'Administrator' account.`nThis password is CRITICAL: It will become the domain Administrator password after DC promotion and is also used for Safe Mode recovery. Save it securely!`nPassword" -AsSecureString
    New-LocalUser -Name "Administrator" -Password $password -FullName "Administrator" -Description "Domain Administrator" -ErrorAction Stop
    Add-LocalGroupMember -Group "Administrators" -Member "Administrator" -ErrorAction Stop
    Write-Host "'Administrator' account created and added to Administrators group."
    Write-Log "'Administrator' account created."
} else {
    Write-Host "'Administrator' account already exists."
    Write-Log "'Administrator' account exists."
    $reset = Read-Host "Do you want to reset the 'Administrator' password? (Y/N)"
    if ($reset -eq "Y" -or $reset -eq "y") {
        $password = Read-Host -Prompt "Enter a new strong password for the 'Administrator' account.`nThis password is CRITICAL: It will become the domain Administrator password after DC promotion and is also used for Safe Mode recovery. Save it securely!`nPassword" -AsSecureString
        Set-LocalUser -Name "Administrator" -Password $password -ErrorAction Stop
        Write-Host "'Administrator' password reset successfully."
        Write-Log "'Administrator' password reset."
    } else {
        $password = Read-Host -Prompt "Enter the existing 'Administrator' password (required for Safe Mode).`nThis must match the current password!`nPassword" -AsSecureString
        Write-Log "'Administrator' password not reset."
    }
}

# Check disk space on C:
$cDrive = Get-PSDrive C
Write-Host "C: drive - Used: $($cDrive.Used / 1GB) GB, Free: $($cDrive.Free / 1GB) GB"
Write-Log "C: drive - Used: $($cDrive.Used / 1GB) GB, Free: $($cDrive.Free / 1GB) GB"
if ($cDrive.Free -lt 5GB) {
    Write-Error "Insufficient free space on C: ($($cDrive.Free / 1GB) GB free). Need at least 5 GB."
    Write-Log "ERROR: Insufficient free space on C:."
    exit 1
}

# Install AD Domain Services and DNS roles
Write-Host "Installing AD Domain Services and DNS roles..."
Write-Log "Installing ADDS and DNS roles..."
Install-WindowsFeature -Name AD-Domain-Services, DNS -IncludeManagementTools -ErrorAction Stop
Write-Log "ADDS and DNS roles installed successfully."

# Set AD storage to C:
$basePath = "C:\AD"
Write-Log "Using $basePath for AD storage."

# Check and create AD storage directories if they don’t exist
$storagePaths = @{
    "DatabasePath" = Join-Path -Path $basePath -ChildPath "Database"  # "C:\AD\Database"
    "LogPath" = Join-Path -Path $basePath -ChildPath "Logs"           # "C:\AD\Logs"
    "SysvolPath" = Join-Path -Path $basePath -ChildPath "SYSVOL"      # "C:\AD\SYSVOL"
}
foreach ($key in $storagePaths.Keys) {
    $path = $storagePaths[$key]
    if (-not (Test-Path $path)) {
        Write-Host "Directory $path does not exist. Creating it now..."
        Write-Log "Creating directory $path..."
        New-Item -Path $path -ItemType Directory -Force -ErrorAction Stop
        Write-Host "Created $path successfully."
        Write-Log "Created $path."
    } else {
        Write-Host "Directory $path already exists."
        Write-Log "$path already exists."
    }
}

# Promote to Domain Controller with dynamic Safe Mode password
Write-Host "Promoting this server to a Domain Controller for $domainName..."
Write-Log "Starting DC promotion for $domainName..."
$safeModePassword = Read-Host -Prompt "Enter a strong password for Safe Mode Administrator.`nThis is CRITICAL for recovery if the DC fails to boot normally. It can be the same as the 'Administrator' password but doesn’t have to be. Save it securely!`nPassword" -AsSecureString
Write-Host "Starting DC promotion process (this may take several minutes)..."
Write-Log "Prompted for Safe Mode password, starting Install-ADDSForest..."
try {
    Install-ADDSForest `
        -DomainName $domainName `
        -DomainNetbiosName $netbiosName `
        -ForestMode $forestMode `
        -DomainMode $domainMode `
        -SafeModeAdministratorPassword $safeModePassword `
        -InstallDns `
        -CreateDnsDelegation:$false `
        -DatabasePath $storagePaths["DatabasePath"] `
        -LogPath $storagePaths["LogPath"] `
        -SysvolPath $storagePaths["SysvolPath"] `
        -Force `
        -ErrorAction Stop `
        -Verbose *>&1 | Out-File -FilePath $logFile -Append
    Write-Log "Install-ADDSForest completed successfully."
} catch {
    Write-Error "DC promotion failed: $_"
    Write-Log "ERROR: DC promotion failed: $_"
    exit 1
}

# Verify ADDS installation before reboot
$addsStatus = Get-WindowsFeature -Name AD-Domain-Services
if ($addsStatus.InstallState -eq "Installed") {
    Write-Host "AD Domain Services installed successfully. Rebooting in 10 seconds..."
    Write-Log "ADDS installed, initiating reboot."
    Start-Sleep -Seconds 10
    Restart-Computer -Force
} else {
    Write-Error "AD Domain Services not installed. Check $logFile for details."
    Write-Log "ERROR: ADDS not installed post-promotion."
    exit 1
}

# Note: Server should reboot if successful
Write-Host "AD DS installation initiated. Server will reboot. After reboot, run 03-verify-dc.ps1 to check status."
Write-Log "AD DS installation initiated, server rebooting."
