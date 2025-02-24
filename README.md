# RHEL Ansible + Kubernetes Infrastructure for IT Support

## Overview
This project establishes a **Red Hat Enterprise Linux (RHEL) 9** virtual machine as a control node, leveraging **Ansible** for configuration management and **Kubernetes** for container orchestration to support IT operations for Managed Service Providers (MSPs). It manages a fleet of remote PCs—**RHEL 9**, **Windows 11 Pro**, **Ubuntu**, and **Fedora CoreOS**—providing tools for monitoring, ticketing, and system administration.

### Features
- **Ansible Control Node**: Manages remote PCs via SSH (Linux) and WinRM (Windows).
- **Kubernetes Cluster**: Runs containerized MSP tools (e.g., Prometheus, Grafana, OSTicket) on the RHEL 9 control node.
- **Remote PCs**: Supports diverse OSes for comprehensive IT management.
- **Automation Scripts**: Simplifies deployment and connectivity setup.

### Prerequisites
- **Control Node**:
  - RHEL 9 VM in VMware Workstation (4GB+ RAM, 2 CPUs, 20GB+ disk).
  - Red Hat subscription for RHEL/Ansilbe repositories.
- **Remote PCs**:
  - RHEL 9, Windows 11 Pro, Ubuntu, Fedora CoreOS VMs on the same subnet (e.g., `192.168.1.0/24`).
  - Network access to the control node (`192.168.1.100`).

### Setup Instructions
1. **Deploy Control Node**:
   - Server: `./deploy/control-server.sh` (installs RHEL 9, Ansible, Kubernetes).
   - Workstation: `./deploy/control-workstation.sh` (configures existing RHEL 9 workstation).
2. **Configure Remote PCs**:
   - Download and run scripts from `remote_scripts/`:
     ```bash
     curl -O https://raw.githubusercontent.com/yourusername/rhel-ansible-k8s-it-support/main/remote_scripts/<script_name>
     ```
   - See [Remote PC Setup](#remote-pc-setup).
3. **Run MSP Tools**:
   ```bash
   ansible-playbook -i ansible/inventory/inventory.yml ansible/playbooks/msp_support.yml --vault-password-file ~/.vault_pass.txt
