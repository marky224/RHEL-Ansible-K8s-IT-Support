# Purpose: Configures DNS settings
param (
    [string]$ConfigPath = "..\configs\dc_config.json"
)

# Load config
$config = Get-Content $ConfigPath | ConvertFrom-Json

# Set DNS forwarder
Set-DnsServerForwarder -IPAddress $config.ForwarderIP

# Verify DNS setup
$zone = Get-DnsServerZone -Name $config.DomainName
if ($zone) {
    Write-Host "DNS zone $($config.DomainName) configured successfully."
} else {
    Write-Error "DNS zone creation failed."
}
