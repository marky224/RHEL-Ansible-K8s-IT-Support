# Remote Scripts - RHEL Ansible + Kubernetes Infrastructure for IT Support

## Overview
The `remote_scripts/` directory contains scripts to configure remote PCs for management by the **Red Hat Enterprise Linux (RHEL) 9** Ansible control node at `192.168.10.100`. These scripts establish SSH (Linux) or WinRM (Windows) connectivity, automate SSH key exchange, and provide robust error handling with logging. The primary focus is the RHEL 9 workstation at `192.168.10.134`, with templates provided for Windows 11 Pro, Ubuntu, and Fedora CoreOS for potential future use.

---

### Files

- **`rhel9_connect.sh`**: Configures the RHEL 9 workstation at `192.168.10.134` for SSH-based Ansible management.
- **`windows_connect.ps1`**: Template to configure Windows 11 Pro for WinRM-based Ansible management.
- **`ubuntu_connect.sh`**: Template to configure Ubuntu for SSH-based Ansible management.
- **`fedora_connect.sh`**: Template to configure Fedora CoreOS for SSH-based Ansible management.

---

### Purpose
These scripts:
- Install prerequisites (`openssh-server`, `curl`) on Linux systems.
- Configure connectivity (SSH for Linux, WinRM for Windows) with firewall rules.
- Automate SSH key exchange by fetching the control node’s public key from `http://192.168.10.100:8080/ssh_key`.
- Log actions and errors to `/var/log/ansible_connect.log` (Linux) or `C:\ansible_connect.log` (Windows).
- Send a check-in to `http://192.168.10.100:8080/checkin` with hostname, IP, and OS details, including retry logic.

---

### Prerequisites
- **Control Node**: RHEL 9 server at `192.168.10.100` with:
  - `scripts/checkin_listener.py` running (`python3 scripts/checkin_listener.py &`).
  - `scripts/ssh_key_server.py` running (`python3 scripts/ssh_key_server.py &`).
- **Network**: Remote PCs on the `192.168.10.0/24` subnet (e.g., VMware Workstation NAT or Bridged network) with internet access.
- **Permissions**: Root privileges on Linux (e.g., `root` user on RHEL 9 workstation).
- **Red Hat Subscription**: Required for RHEL 9 package updates on the workstation.

---

### Usage Instructions

#### General Steps
1. **Download**: Fetch scripts from GitHub using `curl` (Linux) or `Invoke-WebRequest` (Windows).
2. **Make Executable** (Linux): `chmod +x <script_name>`.
3. **Run**: Execute with `sudo` (Linux) or as Administrator (Windows).
4. **Check Logs**: Review `/var/log/ansible_connect.log` (Linux) or `C:\ansible_connect.log` (Windows) for details.

#### Specific Instructions

1. **`rhel9_connect.sh`**
   - **Target**: RHEL 9 workstation at `192.168.10.134`.
   - **Command**:
     ```bash
     curl -O https://raw.githubusercontent.com/marky224/rhel-ansible-k8s-it-support/main/remote_scripts/rhel9_connect.sh
     chmod +x rhel9_connect.sh
     sudo ./rhel9_connect.sh
     ```
   - **Notes**: Validates the workstation’s IP (`192.168.10.134`) and requires a Red Hat subscription for updates.

2. **`windows_connect.ps1`**
   - **Target**: Windows 11 Pro (template; adjust IP if used).
   - **Command**:
     ```powershell
     Invoke-WebRequest -Uri "Invoke-WebRequest -Uri "https://raw.githubusercontent.com/marky224/rhel-ansible-k8s-it-support/main/remote_scripts/windows_connect.ps1" -OutFile "windows_connect.ps1"
.\windows_connect.ps1 -ControlNodeIP "192.168.10.100""
     ```
   - **Notes**: Not currently active in this setup; requires IP specification for use.

3. **`ubuntu_connect.sh`**
   - **Target**: Ubuntu (template; adjust IP if used).
   - **Command**:
     ```bash
     curl -O https://raw.githubusercontent.com/marky224/rhel-ansible-k8s-it-support/main/remote_scripts/ubuntu_connect.sh
     chmod +x ubuntu_connect.sh
     sudo ./ubuntu_connect.sh
     ```
   - **Notes**: Not currently active; intended for future Ubuntu PCs.

4. **`fedora_connect.sh`**
   - **Target**: Fedora CoreOS (template; adjust IP if used).
   - **Command**:
     ```bash
     curl -O https://raw.githubusercontent.com/marky224/rhel-ansible-k8s-it-support/main/remote_scripts/fedora_connect.sh
     chmod +x fedora_connect.sh
     sudo ./fedora_connect.sh
     ```
   - **Notes**: Not currently active; assumes SSH via Ignition.

---

### Enhancements

#### Automated SSH Key Exchange
- **How**: The `rhel9_connect.sh` script fetches the control node’s public key from `http://192.168.10.100:8080/ssh_key` and adds it to `/root/.ssh/authorized_keys` on the workstation.
- **Setup**: Ensure `scripts/ssh_key_server.py` is running on the control node.

#### Improved Error Handling and Logging
- **Error Handling**: Validates the workstation’s IP, exits on failures with specific messages, and retries check-in 3 times with 5-second delays.
- **Logging**: Records all actions and errors to `/var/log/ansible_connect.log` with timestamps for debugging.

---

### Post-Execution
- **Verify**: Check `logs/checkin.log` on the control node at `192.168.10.100` for entries like:
