# Deploy - RHEL Ansible + Kubernetes Infrastructure for IT Support

## Overview
The `deploy/` folder within `remote_scripts/` contains scripts to configure a **Red Hat Enterprise Linux (RHEL) 9** server as an Ansible control node, replicating the production-ready setup established for managing remote PCs. This builds on the project’s foundation, where an RHEL 9 server at `192.168.10.100` was configured to oversee nodes like the RHEL 9 workstation at `192.168.10.134` via static IPs. These scripts streamline the process of provisioning additional control nodes or reconfiguring existing ones for MSP support, ensuring consistency across environments.

---

### Files

- **`control-server.sh`**: Configures an RHEL 9 server as an Ansible control node with a static IP (e.g., `192.168.10.100`), installs Ansible, generates SSH keys, and sets up HTTPS services for key exchange and check-ins.

---

### Purpose
This folder supports the deployment of Ansible control nodes by:
- Setting a static IP and network configuration for reliable management.
- Installing Ansible and required tools securely with interactive Red Hat subscription prompts.
- Automating SSH key generation and HTTPS service setup (`checkin_listener.py`, `ssh_key_server.py`) for remote node connectivity.
- Logging setup details to `/var/log/ansible_control_setup.log` for troubleshooting.

---

### Usage Instructions

#### Specific Instructions

1. **`control-server.sh`**
   - **Target**: RHEL 9 server (e.g., `192.168.10.100` or a new IP like `192.168.10.102`).
   - **Command**:
     ```bash
     cd ~
     mkdir -p scripts
     curl -O https://raw.githubusercontent.com/marky224/rhel-ansible-k8s-it-support/main/Remote%20Scripts/Deploy/control-server.sh
     chmod +x control-server.sh
     sudo ./control-server.sh
     ```
   - **Notes**: 
     - Prompts for Red Hat subscription username and password interactively for security.
     - Assumes `ens160` as the network interface and `192.168.10.1` as the gateway; adjust script if different.
     - Checks for existing Ansible and SSH keys, skipping steps if detected.

---

### Background
Originally developed to replicate the Ansible control node setup at `192.168.10.100`, this script ensures new RHEL 9 servers can seamlessly join the infrastructure. It mirrors the static IP approach used for production-grade reliability, as seen in the management of the RHEL 9 workstation at `192.168.10.134`. By automating network configuration, Ansible installation, and HTTPS services, it reduces manual setup time and maintains consistency for MSP operations requiring robust control nodes.

---

### Next Steps
- Customize the IP address in the script for new control nodes (e.g., `192.168.10.102`).
- Update `ansible/inventory/inventory.yml` with remote node details post-deployment.
- Test connectivity: `ansible -i ansible/inventory/inventory.yml all -m ping`.
