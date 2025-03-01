# Purpose: Installs AD DS and promotes to DC
param (
    [string]$ConfigPath = "..\configs\dc_config.json"
)

# Load config
$config = Get-Content $ConfigPath | ConvertFrom-Json

# Install AD DS role
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Promote to DC
$safeModePw = ConvertTo-SecureString $config.SafeModePassword -AsPlainText -Force
Install-ADDSForest `
    -DomainName $config.DomainName `
    -DomainNetbiosName $config.NetbiosName `
    -ForestMode "Win2025" `
    -DomainMode "Win2025" `
    -DatabasePath $config.DatabasePath `
    -LogPath $config.LogPath `
    -SysvolPath $config.SysvolPath `
    -InstallDns:$true `
    -SafeModeAdministratorPassword $safeModePw `
    -Force
