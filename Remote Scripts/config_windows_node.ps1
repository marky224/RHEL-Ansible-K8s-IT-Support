# PowerShell script to configure Windows 11 Pro worker with static IP and enable WinRM
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
$gateway = (Get-NetRoute -InterfaceAlias $interface -DestinationPrefix "0.0.0.0/0" | Select-Object -ExpandProperty NextHop)
Write-Output "Gateway: $gateway"
Write-Output "OS: $([System.Environment]::OSVersion.VersionString)"
Write-Output "WinRM User: $env:USERNAME"

# Set network profile to Private
Write-Output "Setting network profile to Private for interface $interface..."
Get-NetConnectionProfile -InterfaceAlias $interface | Set-NetConnectionProfile -NetworkCategory Private

# Set static IP to 192.168.10.136 with gateway and local DNS
Write-Output "Setting static IP to 192.168.10.136 on interface $interface..."
Remove-NetIPAddress -InterfaceAlias $interface -Confirm:$false -ErrorAction SilentlyContinue
New-NetIPAddress -InterfaceAlias $interface -IPAddress 192.168.10.136 -PrefixLength 24 -DefaultGateway "192.168.10.1"
Set-DnsClientServerAddress -InterfaceAlias $interface -ServerAddresses ("192.168.10.1")

# Enable WinRM for Ansible
Write-Output "Enabling WinRM for Ansible connectivity..."
winrm quickconfig -q
winrm set winrm/config/service '@{AllowUnencrypted="true"}'  # For testing; use HTTPS in production
Set-Item WSMan:\localhost\Client\TrustedHosts -Value "192.168.10.*" -Force

# Ensure WinRM firewall rule exists
$rule = Get-NetFirewallRule -Name "WinRM-HTTP-In" -ErrorAction SilentlyContinue
if (-not $rule) {
    New-NetFirewallRule -Name "WinRM-HTTP-In" -DisplayName "WinRM HTTP" -Enabled True -Direction Inbound -Protocol TCP -LocalPort 5985 -Action Allow
}

# Verify new configuration
Write-Output "New Configuration:"
Write-Output "Hostname: $env:COMPUTERNAME"
Write-Output "IP: $((Get-NetIPAddress -InterfaceAlias $interface -AddressFamily IPv4).IPAddress)"
Write-Output "Gateway: 192.168.10.1"
Write-Output "DNS Server: 192.168.10.1"
Write-Output "OS: $([System.Environment]::OSVersion.VersionString)"
Write-Output "WinRM User: $env:USERNAME"
Write-Output "WinRM Port: 5985"
Write-Output "WinRM Scheme: http"
Write-Output "Static IP set to 192.168.10.136 and WinRM enabled."
Write-Output "Note: Supply the Administrator password in the Ansible inventory on the control node."
