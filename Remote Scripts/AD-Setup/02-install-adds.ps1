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

# Install AD Domain Services and DNS roles
Write-Host "Installing AD Domain Services and DNS roles..."
Install-WindowsFeature -Name AD-Domain-Services, DNS -IncludeManagementTools -ErrorAction Stop

# Promote to Domain Controller
$safeModePassword = ConvertTo-SecureString "YourSecurePassword123!" -AsPlainText -Force
Write-Host "Promoting this server to a Domain Controller for $domainName..."
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
