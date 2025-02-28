# Remote Scripts

Welcome to the `Remote Scripts` subfolder of the [RHEL-Ansible-K8s-IT-Support](https://github.com/marky224/RHEL-Ansible-K8s-IT-Support) project! This directory contains scripts to configure two remote nodes (one RHEL 9 workstation and one Windows VM), gather inventory details, set up an Ansible control node on RHEL 9, and deploy a Kubernetes cluster for advanced IT MSP production tools.

## Purpose

These scripts configure a RHEL 9 workstation (IP: `192.168.10.134`) and a Windows VM (IP: `192.168.10.136`), gather inventory data, set up an Ansible control node, and deploy Kubernetes for MSP tools (e.g., monitoring, CI/CD). They’re:
- **Simple**: Minimal steps, easy to use.
- **Secure**: Manual key distribution for production quality.
- **Focused**: Tailored for a two-VM setup.

## Scripts

### 1. `configure_rhel9_node.sh`
- **Description**: Configures the RHEL 9 workstation with static IP `192.168.10.134` and gathers inventory details.
- **Features**: Dynamically detects interface, outputs details, sets network config.
- **Usage**:
  1. Save as `configure_rhel9_node.sh` on the RHEL 9 VM.
  2. Make executable: `chmod +x configure_rhel9_node.sh`.
  3. Run as root: `sudo ./configure_rhel9_node.sh`.
  4. Example output:
     ```
     Hostname: workstation1.example.com
     IP: 192.168.10.134
     OS: Red Hat Enterprise Linux 9.3
     SSH User: ansible-user
     SSH Port: 22
     ```

### 2. `configure_windows_node.ps1`
- **Description**: Configures the Windows VM with static IP `192.168.10.136` and gathers inventory details.
- **Features**: Dynamically detects interface, outputs details, sets network config.
- **Usage**:
  1. Save as `configure_windows_node.ps1` on the Windows VM.
  2. Run as admin: `powershell -File configure_windows_node.ps1`.
  3. Example output:
     ```
     Hostname: WIN11-TEST
     IP: 192.168.10.136
     OS: Microsoft Windows NT 10.0.22621.0
     User: Administrator
     ```

### 3. `setup_ansible_control_rhel9.sh`
- **Description**: Sets up an RHEL 9 server as an Ansible control node.
- **Features**:
  - Installs Ansible and SSH client.
  - Creates `ansible` user and SSH key at `/home/ansible/.ssh/id_rsa`.
  - Sets up `/etc/ansible/inventory.ini` and `/etc/ansible/ansible.cfg`.
- **Usage**:
  1. Save as `setup_ansible_control_rhel9.sh`.
  2. Make executable: `chmod +x setup_ansible_control_rhel9.sh`.
  3. Run: `sudo bash setup_ansible_control_rhel9.sh`.
  4. Update inventory with RHEL 9 workstation details:
     ```ini
     [prod]
     workstation1.example.com ansible_host=192.168.10.134

     [prod:vars]
     ansible_user = ansible-user
     ansible_ssh_private_key_file = /home/ansible/.ssh/id_rsa
     ```

### 4. `deploy_kubernetes_rhel9.sh`
- **Description**: Deploys a Kubernetes cluster on the control node and RHEL 9 workstation.
- **Features**: Installs `containerd`, `kubeadm`, joins the cluster.
- **Usage**:
  1. Run after `setup_ansible_control_rhel9.sh`.
  2. Save as `deploy_kubernetes_rhel9.sh`.
  3. Make executable: `chmod +x deploy_kubernetes_rhel9.sh`.
  4. Run: `sudo bash deploy_kubernetes_rhel9.sh`.
  5. Verify: `sudo -u ansible kubectl --kubeconfig=/home/ansible/.kube/config get nodes`.

## Prerequisites

- **Control Node**: RHEL 9 server, 2 CPUs, 2 GB RAM.
- **Remote Nodes**: 
  - 1 RHEL 9 workstation (IP: `192.168.10.134`), 2 GB RAM.
  - 1 Windows VM (IP: `192.168.10.136`, optional).
- **Network**: Control node must reach VMs on port 22 (RHEL) and Kubernetes ports (e.g., 6443).
- **User**: `ansible-user` with `sudo` on RHEL 9 VM.

## Setup Instructions

1. **Prepare Environment**:
   - Boot 1 RHEL 9 control node VM.
   - Boot 1 RHEL 9 workstation VM and 1 Windows VM.
   - Ensure SSH is enabled on RHEL 9: `sudo systemctl enable --now sshd`.

2. **Configure Remote Nodes**:
   - **RHEL 9 Workstation**:
     - Copy: `scp configure_rhel9_node.sh root@<current_ip>:/root/`.
     - Run: `ssh root@<current_ip> "bash configure_rhel9_node.sh"`.
     - Record hostname and confirm IP `192.168.10.134`.
   - **Windows VM**:
     - Copy `configure_windows_node.ps1` via RDP.
     - Run: `powershell -File configure_windows_node.ps1`.
     - Confirm IP `192.168.10.136`.

3. **Configure Control Node**:
   - Clone: `git clone https://github.com/marky224/RHEL-Ansible-K8s-IT-Support.git`.
   - Navigate: `cd RHEL-Ansible-K8s-IT-Support/Remote\ Scripts`.
   - Run: `sudo bash setup_ansible_control_rhel9.sh`.
   - Update `/etc/ansible/inventory.ini` with RHEL 9 workstation hostname.

4. **Distribute SSH Key (RHEL Only)**:
   - Run: `sudo -u ansible ssh-copy-id -i /home/ansible/.ssh/id_rsa.pub ansible-user@192.168.10.134`.

5. **Deploy Kubernetes**:
   - Run: `sudo bash deploy_kubernetes_rhel9.sh`.
   - Verify: `sudo -u ansible kubectl --kubeconfig=/home/ansible/.kube/config get nodes`.

6. **Deploy MSP Tools**:
   - Use `kubectl` to deploy tools on the cluster.

## Best Practices

- **Security**: Secure SSH key; use Kubernetes RBAC.
- **Order**: Configure remote nodes first for accurate inventory.
- **Validation**: Test SSH and IPs before proceeding.

## Contributing

Fork, submit PRs, or open issues to improve!

## License

MIT License—see [LICENSE](https://github.com/marky224/RHEL-Ansible-K8s-IT-Support/blob/main/LICENSE).
