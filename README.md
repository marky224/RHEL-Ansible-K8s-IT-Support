# RHEL Ansible + Kubernetes Infrastructure for IT Support

## Overview
This project establishes a **Red Hat Enterprise Linux (RHEL) 9** virtual machine as a control node, leveraging **Ansible** for configuration management and **Kubernetes** for container orchestration to support IT operations for large interntal IT teams and/or Managed Service Providers (MSPs). It manages a fleet of remote PCs—**Linux**, and **Windows**—providing tools for monitoring, ticketing, and system administration.

### Features
- **Ansible Control Node**: Manages remote PCs via SSH (Linux) and WinRM (Windows).
- **Kubernetes Cluster**: Runs containerized MSP tools (e.g., Prometheus, Grafana, OSTicket) on the control nodes.
- **Remote PCs**: Supports diverse OSes for comprehensive IT management.
- **Automation Scripts**: Simplifies deployment and connectivity setup.

### Prerequisites
- **Control Node**:
  - RHEL 9 VM in VMware Workstation (4GB+ RAM, 4+ CPU Cores, 50GB+ disk).
  - Red Hat subscription for RHEL/Ansilbe repositories.
- **Remote PCs**:
  - RHEL 9, Windows 11 Pro VMs on the same subnet (e.g., `192.168.X.0/24`).
  - Network access to the control node on that subnet (`192.168.X.100`).

### Setup Instructions
1. **Deploy Control Node**:
   - Server: `./deploy/control-server.sh` (installs RHEL 9, Ansible, Kubernetes).
2. **Configure Remote PCs**:
   - Download and run scripts from `remote_scripts/`:
     ```bash
     curl -O https://raw.githubusercontent.com/marky224/rhel-ansible-k8s-it-support/main/remote_scripts/<script_name>
     ```
   - See [Remote PC Setup](#remote-pc-setup).
3. **Run MSP Tools**:
   ```bash
   ansible-playbook -i ansible/inventory/inventory.yml ansible/playbooks/msp_support.yml --vault-password-file ~/.vault_pass.txt
