# 02-install-ad.ps1
# Dynamically set config path relative to script location
$ConfigPath = Join-Path -Path $PSScriptRoot -ChildPath "configs\dc_config.json"

# Verify config file exists
if (-not (Test-Path $ConfigPath)) {
    Write-Error "Config file not found at $ConfigPath. Please ensure dc_config.json exists."
    exit 1
}

# Load config
$config = Get-Content $ConfigPath | ConvertFrom-Json

# Extract domain settings
$domainName = $config.DomainName          # "tech.nexlify.nxl"
$netbiosName = $config.NetbiosName        # "NXL"
$forestMode = $config.ForestMode          # "Win2025"
$domainMode = $config.DomainMode          # "Win2025"

# Check if local 'Admin' account exists
$adminAccount = Get-LocalUser -Name "Admin" -ErrorAction SilentlyContinue
if (-not $adminAccount) {
    Write-Host "Local 'Admin' account not found. Creating it now..."
    # Prompt for a secure password with importance warning
    $password = Read-Host -Prompt "Enter a strong password for the 'Admin' account.`nThis password is CRITICAL: It will become the domain Administrator password after DC promotion and is also used for Safe Mode recovery. Save it securely!`nPassword" -AsSecureString
    # Create the 'Admin' account
    New-LocalUser -Name "Admin" -Password $password -FullName "Administrator" -Description "Domain Administrator" -ErrorAction Stop
    Add-LocalGroupMember -Group "Administrators" -Member "Admin" -ErrorAction Stop
    Write-Host "'Admin' account created and added to Administrators group."
} else {
    Write-Host "'Admin' account already exists."
    # Prompt for password if we need to reset it (optional)
    $reset = Read-Host "Do you want to reset the 'Admin' password? (Y/N)"
    if ($reset -eq "Y" -or $reset -eq "y") {
        $password = Read-Host -Prompt "Enter a new strong password for the 'Admin' account.`nThis password is CRITICAL: It will become the domain Administrator password after DC promotion and is also used for Safe Mode recovery. Save it securely!`nPassword" -AsSecureString
        Set-LocalUser -Name "Admin" -Password $password -ErrorAction Stop
        Write-Host "'Admin' password reset successfully."
    } else {
        $password = Read-Host -Prompt "Enter the existing 'Admin' password (required for Safe Mode).`nThis must match the current password!`nPassword" -AsSecureString
    }
}

# Install AD Domain Services and DNS roles
Write-Host "Installing AD Domain Services and DNS roles..."
Install-WindowsFeature -Name AD-Domain-Services, DNS -IncludeManagementTools -ErrorAction Stop

# Promote to Domain Controller with dynamic Safe Mode password
Write-Host "Promoting this server to a Domain Controller for $domainName..."
# Prompt for Safe Mode password separately
$safeModePassword = Read-Host -Prompt "Enter a strong password for Safe Mode Administrator.`nThis is CRITICAL for recovery if the DC fails to boot normally. It can be the same as the 'Admin' password but doesn’t have to be. Save it securely!`nPassword" -AsSecureString
Write-Host "Starting DC promotion process (this may take several minutes)..."
Install-ADDSForest `
    -DomainName $domainName `
    -DomainNetbiosName $netbiosName `
    -ForestMode $forestMode `
    -DomainMode $domainMode `
    -SafeModeAdministratorPassword $safeModePassword `
    -InstallDns `
    -CreateDnsDelegation:$false `
    -DatabasePath $config.Sites[0].DomainControllers[0].Storage.DatabasePath `
    -LogPath $config.Sites[0].DomainControllers[0].Storage.LogPath `
    -SysvolPath $config.Sites[0].DomainControllers[0].Storage.SysvolPath `
    -Force `
    -ErrorAction Stop

# Note: Server will reboot automatically after promotion
Write-Host "AD DS installation initiated. Server will reboot. After reboot, run a script to set DNS to 192.168.10.10."
