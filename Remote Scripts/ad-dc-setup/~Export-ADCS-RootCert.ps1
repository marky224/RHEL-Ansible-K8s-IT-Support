# Export-ADCS-RootCert.ps1
# Script to export AD CS root certificate in PEM format

# Prompt for output path
$outputPath = Read-Host "Enter the full path where the certificate should be saved (e.g., C:\Temp\rootcert.pem)"

try {
    # Get the root certificate
    $rootCert = Get-ChildItem -Path Cert:\LocalMachine\Root | Where-Object { $_.Issuer -eq $_.Subject }
    if ($null -eq $rootCert) {
        Write-Error "No root certificate found in Local Machine Root store."
        exit 1
    }

    # Export to PEM format
    $certContent = @"
-----BEGIN CERTIFICATE-----
$([Convert]::ToBase64String($rootCert.RawData) | ForEach-Object { $_ -replace '(.{64})', "`$1`n" })
-----END CERTIFICATE-----
"@
    $certContent | Out-File -FilePath $outputPath -Encoding ASCII
    Write-Host "Root certificate exported successfully to $outputPath"
} catch {
    Write-Error "Error exporting certificate: $_"
    exit 1
}
