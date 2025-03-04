# 01-Configure-WinRM-GPO.ps1
# Script to create and configure a GPO for WinRM settings

# Check if running with administrative privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run with administrative privileges."
    exit 1
}

# Import Group Policy module
Import-Module GroupPolicy -ErrorAction Stop

# Variables
$GpoName = "WinRM Configuration"
$Domain = (Get-ADDomain).DNSRoot  # Automatically gets the domain name
$OuPath = "OU=Workstations,DC=domain,DC=com"  # Replace with your target OU
$Description = "Configures WinRM for Ansible management with HTTPS and Kerberos"

try {
    # Check if GPO already exists
    $existingGpo = Get-GPO -Name $GpoName -ErrorAction SilentlyContinue
    if ($null -eq $existingGpo) {
        # Create a new GPO
        $Gpo = New-GPO -Name $GpoName -Comment $Description -ErrorAction Stop
        Write-Host "Created new GPO: $GpoName"
    } else {
        $Gpo = $existingGpo
        Write-Host "GPO '$GpoName' already exists, modifying existing GPO."
    }

    # Define GPO settings as registry-based policies (Administrative Templates)
    # WinRM Service settings under Computer Configuration > Policies > Administrative Templates > Windows Components > Windows Remote Management (WinRM) > WinRM Service

    # "Allow remote server management through WinRM" (Enabled, set to *)
    Set-GPRegistryValue -Name $GpoName -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service" `
        -ValueName "AllowAutoConfig" -Type DWord -Value 1 -ErrorAction Stop
    Set-GPRegistryValue -Name $GpoName -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service" `
        -ValueName "IPv4Filter" -Type String -Value "*" -ErrorAction Stop
    Set-GPRegistryValue -Name $GpoName -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service" `
        -ValueName "IPv6Filter" -Type String -Value "*" -ErrorAction Stop
    Write-Host "Configured 'Allow remote server management through WinRM' to Enabled with '*'."

    # "Allow unencrypted traffic" (Disabled)
    Set-GPRegistryValue -Name $GpoName -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service" `
        -ValueName "AllowUnencryptedTraffic" -Type DWord -Value 0 -ErrorAction Stop
    Write-Host "Configured 'Allow unencrypted traffic' to Disabled."

    # "Allow basic authentication" (Disabled)
    Set-GPRegistryValue -Name $GpoName -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service\Auth" `
        -ValueName "Basic" -Type DWord -Value 0 -ErrorAction Stop
    Write-Host "Configured 'Allow basic authentication' to Disabled."

    # "Allow Kerberos authentication" (Enabled)
    Set-GPRegistryValue -Name $GpoName -Key "HKLM\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service\Auth" `
        -ValueName "Kerberos" -Type DWord -Value 1 -ErrorAction Stop
    Write-Host "Configured 'Allow Kerberos authentication' to Enabled."

    # Firewall settings under Computer Configuration > Policies > Administrative Templates > Network > Network Connections > Windows Defender Firewall > Domain Profile
    # "Windows Defender Firewall: Allow inbound remote administration exception" (Enabled)
    Set-GPRegistryValue -Name $GpoName -Key "HKLM\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile\Services\RemoteAdmin" `
        -ValueName "Enabled" -Type DWord -Value 1 -ErrorAction Stop
    Set-GPRegistryValue -Name $GpoName -Key "HKLM\SOFTWARE\Policies\Microsoft\WindowsFirewall\DomainProfile\Services\RemoteAdmin" `
        -ValueName "RemoteAddresses" -Type String -Value "*" -ErrorAction Stop
    Write-Host "Configured 'Windows Defender Firewall: Allow inbound remote administration exception' to Enabled."

    # Link the GPO to the specified OU if not already linked
    $linked = Get-GPInheritance -Target $OuPath | Select-Object -ExpandProperty GpoLinks | Where-Object { $_.DisplayName -eq $GpoName }
    if (-not $linked) {
        New-GPLink -Name $GpoName -Target $OuPath -LinkEnabled Yes -ErrorAction Stop
        Write-Host "Linked GPO '$GpoName' to '$OuPath'."
    } else {
        Write-Host "GPO '$GpoName' is already linked to '$OuPath'."
    }

    Write-Host "GPO configuration completed successfully for '$GpoName'."
} catch {
    Write-Error "Error configuring GPO: $_"
    exit 1
}
