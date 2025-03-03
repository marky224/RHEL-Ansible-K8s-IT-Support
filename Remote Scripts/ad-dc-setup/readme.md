# Active Directory Domain Controller Setup Scripts

This directory contains a set of PowerShell scripts to automate the provisioning of an Active Directory Domain Controller (DC) on **Windows Server 2025** in an IT-MSP production environment. These scripts streamline authentication setup for Managed Service Providers (MSPs) by configuring a new AD forest and promoting a server to a DC with best practices in mind.

## Project Overview

These scripts are part of the broader [RHEL-Ansible-K8s-IT-Support](https://github.com/marky224/RHEL-Ansible-K8s-IT-Support/blob/main/README.md) repository, which focuses on IT support automation across various platforms. This specific folder, located at [`Remote Scripts/ad-dc-setup/`](https://github.com/marky224/RHEL-Ansible-K8s-IT-Support/tree/main/Remote%20Scripts/ad-dc-setup), targets Windows Server environments.

## Features

- **End-to-End Automation**: From initial checks to post-configuration, fully provision a DC.
- **Production-Ready**: Secure password handling, static IP configuration, and AD best practices.
- **Flexible**: Dynamic network adapter and gateway detection for varied environments.
- **Logging**: Detailed logs in `C:\ADSetup\` for troubleshooting and auditing.

## Prerequisites

- **Operating System**: Fresh installation of Windows Server 2025.
- **Privileges**: Scripts must run with administrative rights (Run as Administrator).
- **Network**: 
  - Server in bridged mode (e.g., VMware Workstation) or on the physical network.
  - Static IP reserved (e.g., `192.168.0.10`) outside DHCP scope.
- **Internet Access**: Required for initial setup (DNS set to `8.8.8.8` pre-promotion).

## Script Files

| File Name                     | Purpose                                                                 |
|-------------------------------|-------------------------------------------------------------------------|
| `00-Install-Updates.ps1`      | (Optional) Installs Windows Updates and reboots if needed.              |
| `01-Check-Prerequisites.ps1`  | Verifies OS, admin privileges, and disk space.                         |
| `02-Set-StaticIP.ps1`         | Configures static IP (`192.168.0.10`) and Google DNS (`8.8.8.8`).       |
| `03-Install-ADDSRole.ps1`     | Installs AD Domain Services role and management tools.                 |
| `04-Promote-DomainController.ps1` | Promotes server to a DC, creates `msp.local` forest, and reboots.  |
| `05-Post-Configuration.ps1`   | Sets DNS to DC (`192.168.0.10`), adds forwarders, and hardens security.|

## Usage

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/marky224/RHEL-Ansible-K8s-IT-Support.git
   cd "RHEL-Ansible-K8s-IT-Support/Remote Scripts/ad-dc-setup"
   ```
## Prerequisites

- **Operating System**: Fresh installation of Windows Server 2025.
- **Privileges**: Scripts must run with administrative rights (Run as Administrator).
- **Network**: 
  - Server in bridged mode (e.g., VMware Workstation) or on the physical network.
  - Static IP reserved (e.g., `192.168.0.10`) outside DHCP scope.
- **Internet Access**: Required for initial setup (DNS set to `8.8.8.8` pre-promotion).


2. **Prepare the Environment:**
  - Install Windows Server 2025 on a VM or physical machine.
  - Ensure bridged network mode (e.g., VMware) or direct network access.
  - Copy scripts to C:\Configuration\ on the target server.

3. **Run the Scripts**:
  - Open PowerShell as Administrator:
powershell
```
cd C:\Configuration
.\00-Install-Updates.ps1        # Optional - updates and reboots if needed
.\01-Check-Prerequisites.ps1    # Verify prerequisites
.\02-Set-StaticIP.ps1           # Set static IP and DNS
.\03-Install-ADDSRole.ps1       # Install AD DS role
.\04-Promote-DomainController.ps1 # Promote to DC (reboots)
```
  - After reboot, log in as Administrator (or MSP\Administrator) and run:
powershell
```
cd C:\Configuration
.\05-Post-Configuration.ps1     # Finalize DNS and security
```

4. **Verify Setup**:
  - Check IP settings:
powershell
```
ipconfig
```
    - Expected: IP = 192.168.0.10, DNS = 192.168.0.10
  - Test AD and DNS:
powershell
```
dcdiag
nslookup msp.local  # Should resolve to 192.168.0.10
ping google.com     # Via forwarders 8.8.8.8, 8.8.4.4
```
  - Open dsa.msc to confirm msp.local domain.

## Configuration Details
  - Static IP: 192.168.0.10 with subnet 255.255.255.0 (adjustable in 02-Set-StaticIP.ps1).
  - Domain: Creates msp.local with NetBIOS name MSP (customizable in 04-Promote-DomainController.ps1).
-  DNS:
    - Pre-promotion: 8.8.8.8 for internet access.
    - Post-promotion: 192.168.0.10 with forwarders 8.8.8.8, 8.8.4.4.
  -Network Profile: Set to Private for AD compatibility.

## Notes
  - **Password Security**: During 04-Promote-DomainController.ps1, save the Administrator/DSRM password securely (e.g., in a password manager).
  - **VMware**: Tested in bridged mode; NAT or isolated subnets may require adjustments.
  ` **Default Gateway to Router**: Assumes gateway 192.168.0.1. Reserve 192.168.0.10 in DHCP if applicable.

## Contributing
- Feel free to fork, enhance, or submit pull requests! Suggestions for redundancy (e.g., second DC), additional hardening, or MSP-specific features are welcome.

## License
- This project is licensed under the MIT License (or specify your preferred license).

## Acknowledgments
- Designed for IT-MSPs to streamline authentication in production environments.
