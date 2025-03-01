# Purpose: Applies security baseline via GPO
param (
    [string]$ConfigPath = "..\configs\dc_config.json"
)

# Load config
$config = Get-Content $ConfigPath | ConvertFrom-Json

# Create and link GPO
$gpo = New-GPO -Name "DC_Security_Baseline" -Comment "Hardening for Domain Controllers"
$gpo | New-GPLink -Target "OU=Domain Controllers,DC=corp,DC=companyname,DC=local"

# Disable NTLM (optional, test in your environment)
Set-GPRegistryValue -Name "DC_Security_Baseline" -Key "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" -ValueName "RestrictNTLM" -Type DWord -Value 1

# Enable SMB signing
Set-GPRegistryValue -Name "DC_Security_Baseline" -Key "HKLM\SYSTEM\CurrentControlSet\Services\LanManServer\Parameters" -ValueName "RequireSecuritySignature" -Type DWord -Value 1

# Force GPO update
gpupdate /force
