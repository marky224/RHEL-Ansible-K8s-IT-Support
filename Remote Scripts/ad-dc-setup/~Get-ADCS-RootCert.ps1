# ~Get-ADCS-RootCert.ps1
# Script to locate and display the AD CS root certificate in PEM format for copying

# Check if running with administrative privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run with administrative privileges."
    exit 1
}

try {
    # Find the self-signed root certificate in the Local Machine Root store
    $rootCert = Get-ChildItem -Path Cert:\LocalMachine\Root | Where-Object { $_.Issuer -eq $_.Subject } | Select-Object -First 1
    if ($null -eq $rootCert) {
        Write-Error "No self-signed root certificate found in Cert:\LocalMachine\Root. Ensure AD CS is installed and configured."
        exit 1
    }

    # Convert the certificate to Base64
    $base64 = [Convert]::ToBase64String($rootCert.RawData)

    # Format as PEM with 64-character line breaks
    $pemContent = "-----BEGIN CERTIFICATE-----`n"
    $pemContent += ($base64 -replace '(.{64})', "`$1`n").Trim()
    $pemContent += "`n-----END CERTIFICATE-----"

    # Display the certificate details
    Write-Host "Found AD CS Root Certificate:"
    Write-Host "Subject: $($rootCert.Subject)"
    Write-Host "Thumbprint: $($rootCert.Thumbprint)"
    Write-Host "Issuer: $($rootCert.Issuer)"
    Write-Host "`nBelow is the PEM-formatted certificate. Copy the entire block (including BEGIN/END lines) to paste into the target machine:`n"
    Write-Host $pemContent -ForegroundColor Green
    Write-Host "`nTip: Click the PowerShell icon in the title bar, select 'Edit' > 'Copy' to copy the output."

} catch {
    Write-Error "Error retrieving or formatting the certificate: $_"
    exit 1
}
