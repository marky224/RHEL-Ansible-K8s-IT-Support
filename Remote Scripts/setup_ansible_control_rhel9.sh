#!/bin/bash
# Script to set up an Ansible control node on RHEL 9 server (Kubernetes control plane)
# Run as root (sudo) after configuring remote nodes

set -e

echo "Configuring Ansible control node on RHEL 9 server..."

# 1. Install prerequisites
dnf install -y ansible openssh-clients

# 2. Create Ansible user
useradd -m ansible

# 3. Generate SSH key pair
sudo -u ansible mkdir -p /home/ansible/.ssh
sudo -u ansible ssh-keygen -t rsa -b 4096 -f /home/ansible/.ssh/id_rsa -N "" -q
chown ansible:ansible /home/ansible/.ssh/id_rsa /home/ansible/.ssh/id_rsa.pub
chmod 600 /home/ansible/.ssh/id_rsa
chmod 644 /home/ansible/.ssh/id_rsa.pub

# 4. Create Ansible directory and inventory
mkdir -p /etc/ansible
cat <<EOF > /etc/ansible/inventory.ini
[control]
localhost ansible_connection=local

[workers]
workstation1.example.com ansible_host=192.168.10.134
WIN11-TEST ansible_host=192.168.10.136 ansible_connection=winrm ansible_user=Administrator ansible_password=your_password ansible_winrm_transport=ntlm ansible_port=5985 ansible_winrm_scheme=http

[all:vars]
ansible_ssh_private_key_file = /home/ansible/.ssh/id_rsa
ansible_user = ansible-user  # For RHEL
EOF
chown -R ansible:ansible /etc/ansible
chmod 644 /etc/ansible/inventory.ini

# 5. Configure Ansible
cat <<EOF > /etc/ansible/ansible.cfg
[defaults]
inventory = /etc/ansible/inventory.ini
remote_user = ansible-user
private_key_file = /home/ansible/.ssh/id_rsa
host_key_checking = False

[ssh_connection]
pipelining = True
retries = 3
EOF
chown ansible:ansible /etc/ansible/ansible.cfg
chmod 644 /etc/ansible/ansible.cfg

# 6. Harden SSH
sed -i 's/#PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl reload sshd

# 7. Create Kubernetes deployment playbook
mkdir -p /etc/ansible/playbooks
cat <<EOF > /etc/ansible/playbooks/deploy_kubernetes.yml
---
- name: Configure RHEL 9 Kubernetes prerequisites
  hosts: all:!ansible_host=192.168.10.136  # RHEL nodes only
  become: yes
  tasks:
    - name: Disable swap
      shell: swapoff -a && sed -i '/swap/d' /etc/fstab
      args:
        warn: no

    - name: Install containerd
      dnf:
        name: containerd.io
        state: present

    - name: Enable containerd
      systemd:
        name: containerd
        enabled: yes
        state: started

    - name: Add Kubernetes repo
      copy:
        content: |
          [kubernetes]
          name=Kubernetes
          baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
          enabled=1
          gpgcheck=1
          gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
        dest: /etc/yum.repos.d/kubernetes.repo

    - name: Install Kubernetes components
      dnf:
        name: "{{ item }}"
        state: present
      loop:
        - kubeadm-1.29.2
        - kubelet-1.29.2
        - kubectl-1.29.2

    - name: Enable kubelet
      systemd:
        name: kubelet
        enabled: yes

- name: Configure Windows 11 Pro Kubernetes prerequisites
  hosts: ansible_host=192.168.10.136  # Windows node only
  tasks:
    - name: Enable Hyper-V
      win_feature:
        name: Microsoft-Hyper-V-All
        state: present
      register: hyperv_result
      ignore_errors: yes  # May already be enabled

    - name: Install Chocolatey
      win_shell: Set-ExecutionPolicy Bypass -Scope CurrentUser -Force; iwr https://chocolatey.org/install.ps1 -UseBasicParsing | iex
      args:
        executable: powershell.exe
      register: choco_install
      changed_when: choco_install.rc == 0

    - name: Install containerd via Chocolatey
      win_chocolatey:
        name: containerd
        state: present

    - name: Download Kubernetes binaries
      win_get_url:
        url: "https://dl.k8s.io/v1.29.2/kubernetes-node-windows-amd64.tar.gz"
        dest: "C:\\k8s\\kubernetes-node-windows-amd64.tar.gz"
      register: k8s_download

    - name: Extract Kubernetes binaries
      win_unzip:
        src: "C:\\k8s\\kubernetes-node-windows-amd64.tar.gz"
        dest: "C:\\k8s"
      when: k8s_download.changed

    - name: Add Kubernetes to PATH
      win_path:
        elements: "C:\\k8s\\kubernetes\\node\\bin"

- name: Initialize Kubernetes control plane on RHEL 9 server
  hosts: control
  become: yes
  tasks:
    - name: Initialize cluster
      shell: kubeadm init --pod-network-cidr=10.244.0.0/16
      register: kubeadm_init
      changed_when: kubeadm_init.rc == 0

    - name: Create .kube directory
      file:
        path: /home/ansible/.kube
        state: directory
        owner: ansible
        group: ansible

    - name: Copy admin config
      copy:
        src: /etc/kubernetes/admin.conf
        dest: /home/ansible/.kube/config
        owner: ansible
        group: ansible
        remote_src: yes

    - name: Install Flannel CNI
      shell: kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml
      environment:
        KUBECONFIG: /home/ansible/.kube/config

- name: Join RHEL 9 worker node
  hosts: workers:!ansible_host=192.168.10.136
  become: yes
  tasks:
    - name: Join cluster
      shell: "{{ hostvars['localhost']['kubeadm_init'].stdout | regex_search('kubeadm join.*token.*') }}"
      when: hostvars['localhost']['kubeadm_init'].rc == 0

- name: Join Windows 11 Pro worker node
  hosts: ansible_host=192.168.10.136
  tasks:
    - name: Join cluster
      win_shell: "kubeadm join {{ hostvars['localhost']['kubeadm_init'].stdout | regex_search('192.168.10.[0-9]+:6443') }} --token {{ hostvars['localhost']['kubeadm_init'].stdout | regex_search('--token [^. ]+') | split(' ') | last }} --discovery-token-ca-cert-hash {{ hostvars['localhost']['kubeadm_init'].stdout | regex_search('--discovery-token-ca-cert-hash sha256:[a-f0-9]+') | split(' ') | last }}"
      when: hostvars['localhost']['kubeadm_init'].rc == 0
EOF
chown ansible:ansible /etc/ansible/playbooks/deploy_kubernetes.yml

# 8. Instructions
echo "Ansible control node setup complete!"
echo "Next steps:"
echo "1. Replace 'workstation1.example.com' and Windows credentials in /etc/ansible/inventory.ini with real values."
echo "2. Distribute SSH key to RHEL worker: sudo -u ansible ssh-copy-id -i /home/ansible/.ssh/id_rsa.pub ansible-user@192.168.10.134"
echo "3. Test Ansible: sudo -u ansible ansible all -m ping"
echo "4. Deploy Kubernetes: sudo -u ansible ansible-playbook /etc/ansible/playbooks/deploy_kubernetes.yml"
echo "5. Verify Kubernetes: sudo -u ansible kubectl --kubeconfig=/home/ansible/.kube/config get nodes"
