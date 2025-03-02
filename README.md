# RHEL Ansible + Kubernetes Infrastructure for IT Support

## Overview
This project establishes a **Red Hat Enterprise Linux (RHEL) 9 virtual machine** as a control node, leveraging **Ansible** for configuration management and **Kubernetes** for container orchestration to support IT operations for large internal IT teams and/or Managed Service Providers (MSPs). It manages a fleet of remote PCs—Linux and Windows—providing tools for monitoring, ticketing, and system administration.

The infrastructure integrates an **Active Directory Domain Controller (AD DC)** for centralized authentication and DNS, enabling seamless management of diverse operating systems and containerized services.

## Features
- **Ansible Control Node**: Manages remote PCs via SSH (Linux) and WinRM (Windows).
- **Kubernetes Cluster**: Runs containerized MSP tools (e.g., Prometheus, Grafana, OSTicket) on the control node or additional nodes.
- **Active Directory Integration**: Provides centralized identity and DNS services for Ansible and Kubernetes.
- **Remote PCs**: Supports diverse OSes (RHEL 9, Windows 11 Pro) for comprehensive IT management.
- **Automation Scripts**: Simplifies deployment and connectivity setup across AD, Ansible, and Kubernetes.

## Repository Structure
```
Main-Repository/
├── Remote-Scripts/           # Scripts for remote management
│   ├── AD-Setup/            # Active Directory setup scripts
│   └── [Other Subfolders]   # Future Ansible/Kubernetes scripts
├── README.md                # This file
└── .gitignore               # Exclusions for sensitive data
```

## Prerequisites

### Control Node
- **RHEL 9 VM in VMware Workstation**:
  - 4GB+ RAM, 4+ CPU cores, 50GB+ disk space.
  - Static IP (e.g., `192.168.X.100`) on a dedicated subnet (e.g., `192.168.X.0/24`).
- **Red Hat Subscription**: Required for RHEL and Ansible repositories.
- **Software**: Ansible installed, Kubernetes (e.g., via Minikube or Kubeadm) planned.

### Remote PCs
- **RHEL 9 VMs**: Configured with SSH and AD integration (via `realmd`/SSSD).
- **Windows 11 Pro VMs**: Configured with WinRM and joined to AD.
- **Network**: Same subnet as the control node (e.g., `192.168.X.0/24`), with access to the control node (`192.168.X.100`).

### Active Directory Domain Controller
- **Windows Server 2025 VM**: Runs AD DS and DNS, configured via `Remote-Scripts/AD-Setup/`.
- **Network**: Same subnet, static IP (e.g., `192.168.X.10`).

## Setup Instructions
1. **Deploy AD DC**:
   - Navigate to `Remote-Scripts/AD-Setup/`.
   - Edit `configs/dc_config.json` with your domain and network details.
   - Run scripts in sequence (e.g., `01-prepare.ps1`, `02-install-adds.ps1`).

2. **Configure Control Node**:
   - Install RHEL 9 on the VM, activate subscription, and install Ansible.
   - Join the AD domain for centralized authentication.

3. **Set Up Remote PCs**:
   - Configure Linux PCs with SSH and AD (SSSD).
   - Configure Windows PCs with WinRM and AD domain membership.

4. **Deploy Kubernetes**:
   - Install Kubernetes on the control node or additional nodes.
   - Deploy containerized tools (e.g., Prometheus, Grafana, OSTicket).

## Next Steps
- Finalize AD configuration in `AD-Setup/configs/dc_config.json`.
- Develop Ansible playbooks for remote node management.
- Script Kubernetes cluster deployment and tool installation.

## Contributing
- Add scripts to `Remote-Scripts/` for Ansible or Kubernetes tasks.
- Update documentation in subfolder READMEs as the project evolves.
