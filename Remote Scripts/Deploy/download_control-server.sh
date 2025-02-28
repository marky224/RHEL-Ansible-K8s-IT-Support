# Manually install on PC with internet access
sudo mkdir -p /root/rhel-ansible-k8s
sudo cd /root/rhel-ansible-k8s
curl -O https://raw.githubusercontent.com/marky224/RHEL-Ansible-K8s-IT-Support/main/deploy/control-server.sh
sudo mkdir scripts
sudo cd scripts
curl -O https://raw.githubusercontent.com/marky224/RHEL-Ansible-K8s-IT-Support/main/scripts/Dockerfile
curl -O https://raw.githubusercontent.com/marky224/RHEL-Ansible-K8s-IT-Support/main/scripts/entrypoint.sh
curl -O https://raw.githubusercontent.com/marky224/RHEL-Ansible-K8s-IT-Support/main/scripts/checkin_listener.py
curl -O https://raw.githubusercontent.com/marky224/RHEL-Ansible-K8s-IT-Support/main/scripts/ssh_key_server.py
