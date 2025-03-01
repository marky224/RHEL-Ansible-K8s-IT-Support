# PowerShell script to configure Windows 11 Pro worker with static IP and enable WinRM over HTTPS
# Run as Administrator

# Dynamically detect the first active non-loopback interface
$interface = (Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.Name -notlike "*Loopback*" } | Select-Object -First 1).Name
if (-not $interface) {
    Write-Output "Error: No active non-loopback network interface found."
    exit 1
}

# Gather current info
Write-Output "Current Configuration:"
Write-Output "Hostname: $env:COMPUTERNAME"
Write-Output "IP: $((Get-NetIPAddress -InterfaceAlias $interface -AddressFamily IPv4).IPAddress)"
Write-Output "OS: $([System.Environment]::OSVersion.VersionString)"
Write-Output "User: $env:USERNAME"

# Set static IP to 192.168.10.136
Write-Output "Setting static IP to 192.168.10.136 on interface $interface..."
New-NetIPAddress -InterfaceAlias $interface -IPAddress 192.168.10.136 -PrefixLength 24 -DefaultGateway 192.168.10.1
Set-DnsClientServerAddress -InterfaceAlias $interface -ServerAddresses ("8.8.8.8", "8.8.4.4")

# Enable WinRM over HTTPS
Write-Output "Enabling WinRM over HTTPS for Ansible connectivity..."

# Generate a self-signed certificate
$cert = New-SelfSignedCertificate -DnsName $env:COMPUTERNAME -CertStoreLocation "Cert:\LocalMachine\My"
$thumbprint = $cert.Thumbprint

# Configure WinRM HTTPS listener
winrm quickconfig -q
winrm create winrm/config/Listener?Address=*+Transport=HTTPS "@{Hostname=`"$env:COMPUTERNAME`";CertificateThumbprint=`"$thumbprint`"}"
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "192.168.10.*" -Force

# Add firewall rule for WinRM HTTPS (port 5986) on Public networks
Write-Output "Adding WinRM HTTPS firewall rule for Public networks..."
New-NetFirewallRule -DisplayName "Allow WinRM HTTPS" -Direction Inbound -Protocol TCP -LocalPort 5986 -Action Allow -Profile Public -RemoteAddress 192.168.10.0/24

# Verify new IP and WinRM status
Write-Output "New Configuration:"
Write-Output "Hostname: $env:COMPUTERNAME"
Write-Output "IP: $((Get-NetIPAddress -InterfaceAlias $interface -AddressFamily IPv4).IPAddress)"
Write-Output "OS: $([System.Environment]::OSVersion.VersionString)"
Write-Output "User: $env:USERNAME"
Write-Output "Static IP set to 192.168.10.136 and WinRM enabled over HTTPS (port 5986)."
