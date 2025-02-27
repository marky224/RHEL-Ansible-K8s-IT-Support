# Remote Scripts - RHEL Ansible + Kubernetes Infrastructure for IT Support

## Overview
The `remote_scripts/` directory contains scripts to configure remote PCs for management by the **Red Hat Enterprise Linux (RHEL) 9** Ansible control node at `192.168.10.100`. These scripts establish SSH (Linux) or WinRM (Windows) connectivity, automate SSH key exchange for Linux systems, and provide robust error handling with logging. The primary focus is the RHEL 9 workstation at `192.168.10.134`, with templates provided for Windows 11 Pro, Ubuntu, and Fedora CoreOS for potential future use.

---

### Files

- **`rhel9_connect.sh`**: Configures the RHEL 9 workstation at `192.168.10.134` for SSH-based Ansible management.
- **`windows_connect.ps1`**: Template to configure Windows 11 Pro for WinRM-based Ansible management, with interactive username/password prompts.
- **`ubuntu_connect.sh`**: Template to configure Ubuntu for SSH-based Ansible management.
- **`fedora_connect.sh`**: Template to configure Fedora CoreOS for SSH-based Ansible management.

---

### Purpose
These scripts:
- Install prerequisites (e.g., `openssh-server`, `curl` for Linux).
- Configure connectivity (SSH for Linux, WinRM for Windows) with firewall rules.
- Automate SSH key exchange for Linux by fetching the control node’s public key from `https://192.168.10.100:8080/ssh_key`.
- Log actions and errors to `/var/log/ansible_connect.log` (Linux) or `C:\ansible_connect.log` (Windows).
- Send a check-in to `https://192.168.10.100:8080/checkin` with hostname, IP, and OS details, including retry logic.

---

### Prerequisites
- **Control Node**: RHEL 9 server at `192.168.10.100` with:
  - `scripts/checkin_listener.py` running with HTTPS (`python3 scripts/checkin_listener.py &`).
  - `scripts/ssh_key_server.py` running with HTTPS (`python3 scripts/ssh_key_server.py &`).
- **Network**: Remote PCs on the `192.168.10.0/24` subnet (e.g., VMware Workstation NAT or Bridged) with internet access.
- **Permissions**: Root privileges on Linux (e.g., `root` on RHEL 9 workstation); Administrator on Windows
