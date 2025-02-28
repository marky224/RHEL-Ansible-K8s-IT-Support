# Remote Scripts

Welcome to the `Remote Scripts` subfolder of the [RHEL-Ansible-K8s-IT-Support](https://github.com/marky224/RHEL-Ansible-K8s-IT-Support) project! This directory contains scripts to configure a RHEL 9 workstation and a Windows 11 Pro VM as Kubernetes worker nodes, set up an RHEL 9 server as the Ansible control node and Kubernetes control plane, and deploy a cluster for IT MSP production tools.

## Purpose

These scripts configure a RHEL 9 workstation (IP: `192.168.10.134`) and a Windows 11 Pro VM (IP: `192.168.10.136`) as Kubernetes workers, with an RHEL 9 server as the control plane, using Ansible for centralized deployment of MSP tools (e.g., monitoring, CI/CD). They’re:
- **Simple**: Minimal worker setup, centralized control.
- **Secure**: Manual key distribution, WinRM prep script.
- **Scalable**: Easily add more Linux/Windows workers.

## Scripts

### 1. `config_rhel9_node.sh`
- **Description**: Configures the RHEL 9 workstation worker with static IP `192.168.10.134` and gathers inventory details.
- **Features**: Dynamically detects interface, outputs details, sets network config.
- **Usage**:
  1. Save as `config_rhel9_node.sh` on the RHEL 9 VM.
  2. Make executable: `chmod +x config_rhel9_node.sh`.
  3. Run as root: `sudo ./config_rhel9_node.sh`.
  4. Example output:
     ```
     Hostname: workstation1.example.com
     IP: 192.168.10.134
     OS: Red Hat Enterprise Linux 9.3
     SSH User: ansible-user
     SSH Port: 22
     ```

### 2. `config_windows_node.ps1`
- **Description**: Configures the Windows 11 Pro worker with static IP `192.168.10.136`, enables WinRM, and gathers inventory details.
- **Features**: Dynamically detects interface, sets network config, prepares for Ansible.
- **Usage**:
  1. Save as `config_windows_node.ps1` on the Windows 11 Pro VM.
  2. Run as admin: `powershell -ExecutionPolicy Bypass -File .\configure_windows_node.ps1`.
  3. Example output:
     ```
     Hostname: WIN11-TEST
     IP: 192.168.10.136
     OS: Microsoft Windows NT 10.0.22621.0
     User: Administrator
     ```

### 3. `setup_ansible_control_rhel9.sh`
- **Description**: Sets up an RHEL 9 server as the Ansible control node and Kubernetes control plane, preparing to join workers.
- **Features**:
  - Installs Ansible and SSH client.
  - Creates `ansible` user and SSH key at `/home/ansible/.ssh/id_rsa`.
  - Sets up `/etc/ansible/inventory.ini`, `/etc/ansible/ansible.cfg`, and `deploy_kubernetes.yml`.
- **Usage**:
  1. Save as `setup_ansible_control_rhel9.sh`.
  2. Make executable: `chmod +x setup_ansible_control_rhel9.sh`.
  3. Run: `sudo bash setup_ansible_control_rhel9.sh`.
  4. Update inventory with RHEL 9 and Windows details:
     ```ini
     [control]
     localhost ansible_connection=local

     [workers]
     workstation1.example.com ansible_host=192.168.10.134
     WIN11-TEST ansible_host=192.168.10.136 ansible_connection=winrm ansible_user=Administrator ansible_password=your_password ansible_winrm_transport=ntlm ansible_port=5985 ansible_winrm_scheme=http

     [all:vars]
     ansible_ssh_private_key_file = /home/ansible/.ssh/id_rsa
     ansible_user = ansible-user  # For RHEL
     ```

## Prerequisites

- **Control Node**: RHEL 9 server (control plane), 2 CPUs, 2 GB RAM.
- **Worker Nodes**: 
  - RHEL 9 workstation (IP: `192.168.10.134`), 2 GB RAM.
  - Windows 11 Pro VM (IP: `192.168.10.136`), Hyper-V enabled, 2 GB RAM.
- **Network**: Control node must reach RHEL on port 22 (SSH), Windows on 5985 (WinRM), and Kubernetes ports (e.g., 6443).
- **User**: `ansible-user` with `sudo` on RHEL; admin on Windows with password supplied in inventory.

## Setup Instructions

1. **Prepare Environment**:
   - Boot 1 RHEL 9 server VM (control plane).
   - Boot 1 RHEL 9 workstation VM and 1 Windows 11 Pro VM (workers).
   - Enable SSH on RHEL: `sudo systemctl enable --now sshd`.

2. **Configure RHEL 9 Workstation Worker**:
   - Copy: `scp config_rhel9_node.sh root@<current_ip>:/root/`.
   - Run: `ssh root@<current_ip> "bash config_rhel9_node.sh"`.
   - Record hostname and confirm IP `192.168.10.134`.

3. **Configure Windows 11 Pro Worker**:
   - Copy `config_windows_node.ps1` to the Windows VM (e.g., via RDP).
   - Run as admin: `powershell -File config_windows_node.ps1`.
   - Confirm IP `192.168.10.136` and WinRM enabled.

4. **Configure Control Node**:
   - Clone: `git clone https://github.com/marky224/RHEL-Ansible-K8s-IT-Support.git`.
   - Navigate: `cd RHEL-Ansible-K8s-IT-Support/Remote\ Scripts`.
   - Run: `sudo bash setup_ansible_control_rhel9.sh`.
   - Update `/etc/ansible/inventory.ini` with RHEL hostname and Windows admin password.

5. **Distribute SSH Key (RHEL Worker Only)**:
   - Run: `sudo -u ansible ssh-copy-id -i /home/ansible/.ssh/id_rsa.pub ansible-user@192.168.10.134`.

6. **Deploy Kubernetes**:
   - Run: `sudo -u ansible ansible-playbook /etc/ansible/playbooks/deploy_kubernetes.yml`.
   - Verify: `sudo -u ansible kubectl --kubeconfig=/home/ansible/.kube/config get nodes`.

7. **Add More Workers (Future)**:
   - For RHEL: Reuse `config_rhel9_node.sh` with a new IP, add to `[workers]` in inventory.
   - For Windows: Reuse `config_windows_node.ps1`, add to `[workers]` with WinRM settings.

8. **Deploy MSP Tools**:
   - Use `kubectl` to deploy tools on the cluster.

## Best Practices

- **Separation**: Distinct worker scripts simplify scaling.
- **Centralized Deployment**: Ansible manages Kubernetes across nodes.
- **Security**: Supply Windows password in inventory; use HTTPS WinRM in production.
- **Validation**: Test connectivity and node status post-deployment.

## Contributing

Fork, submit PRs, or open issues to improve!

## License

MIT License—see [LICENSE](https://github.com/marky224/RHEL-Ansible-K8s-IT-Support/blob/main/LICENSE).
