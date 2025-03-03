# ~Create-EmptyScripts.ps1
# Creates empty PowerShell files in C:\Configuration for AD DC provisioning

# Set strict mode and error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Define the target folder path
$folderPath = "C:\Configuration"

# List of script filenames to create
$scriptNames = @(
    "01-Check-Prerequisites.ps1",
    "02-Set-StaticIP.ps1",
    "03-Install-ADDSRole.ps1",
    "04-Promote-DomainController.ps1",
    "05-Post-Configuration.ps1"
)

# Check if the folder exists, create it if it doesn’t
if (-not (Test-Path $folderPath)) {
    Write-Host "Folder $folderPath does not exist. Creating it..." -ForegroundColor Yellow
    New-Item -Path $folderPath -ItemType Directory -Force | Out-Null
    Write-Host "Folder created successfully." -ForegroundColor Green
} else {
    Write-Host "Folder $folderPath already exists." -ForegroundColor Green
}

# Create each empty script file
foreach ($script in $scriptNames) {
    $filePath = Join-Path -Path $folderPath -ChildPath $script
    if (-not (Test-Path $filePath)) {
        Write-Host "Creating $script..." -ForegroundColor Yellow
        New-Item -Path $filePath -ItemType File -Force | Out-Null
        Write-Host "$script created successfully." -ForegroundColor Green
    } else {
        Write-Host "$script already exists. Skipping creation." -ForegroundColor Yellow
    }
}

Write-Host "All script files have been created in $folderPath." -ForegroundColor Green