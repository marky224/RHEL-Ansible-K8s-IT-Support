# Purpose: Adds a second DC to the domain
param (
    [string]$ConfigPath = "..\configs\dc_config.json"
)

# Load config
$config = Get-Content $ConfigPath | ConvertFrom-Json

# Install AD DS role
Install-WindowsFeature -Name AD-Domain-Services -IncludeManagementTools

# Promote as additional DC
$safeModePw = ConvertTo-SecureString $config.SafeModePassword -AsPlainText -Force
Install-ADDSDomainController `
    -DomainName $config.DomainName `
    -InstallDns:$true `
    -SafeModeAdministratorPassword $safeModePw `
    -Force
