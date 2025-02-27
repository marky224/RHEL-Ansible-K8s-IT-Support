# File Structure - RHEL Ansible + Kubernetes Infrastructure for IT Support

'''rhel-ansible-k8s-it-support/
├── ansible/                    # Ansible configuration
│   ├── inventory/              # Inventory and secrets for managed systems
│   │   ├── inventory.yml       # Main inventory file for VMs
│   │   └── vault.yml           # Encrypted variables (e.g., Windows password)
│   ├── playbooks/              # Ansible playbooks for various tasks
│   │   ├── setup-ansible.yml   # Installs Ansible on RHEL 9 (optional)
│   │   ├── manage_vms.yml      # Basic VM management tasks
│   │   └── msp_support.yml     # Deploys MSP tools and collects metrics
│   └── roles/                  # Reusable Ansible roles
│       ├── monitoring/         # Role for monitoring setup
│       │   ├── tasks/          # Tasks for monitoring configuration
│       │   └── templates/      # Templates for monitoring setup
│       └── patching/           # Role for VM patching
│           ├── tasks/          # Tasks for patching configuration
│           └── templates/      # Templates for patching setup
├── kubernetes/                 # Kubernetes configuration for MSP tools
│   ├── manifests/              # Kubernetes manifests
│   │   ├── prometheus.yml      # Prometheus deployment
│   │   ├── grafana.yml         # Grafana deployment
│   │   └── osticket.yaml       # OSTicket deployment
│   └── scripts/                # Kubernetes setup scripts
│       └── setup-k8s.sh        # Script to install Kubernetes on RHEL 9
├── deploy/                     # Deployment scripts for control node
│   ├── control-server.sh       # Deploys RHEL 9 server with Ansible + Kubernetes
│   └── control-workstation.sh  # Configures existing RHEL 9 workstation
├── remote_scripts/             # Scripts to connect remote PCs to the control node
│   ├── rhel9_connect.sh        # Configures RHEL 9 remote PC
│   ├── windows_connect.ps1     # Configures Windows 11 Pro remote PC
│   ├── ubuntu_connect.sh       # Configures Ubuntu remote PC
│   ├── fedora_connect.sh       # Configures Fedora CoreOS remote PC
│   └── install-agent.sh        # Generic script for agent setup (future use)
│   └── README.md               # Documentation for remote scripts
├── scripts/                    # General utility scripts
│   ├── create-vm.ps1           # PowerShell script to create Windows 11 VM (optional)
│   ├── precheck.sh             # Pre-check script for VM connectivity
│   ├── metrics_collector.sh    # Script to collect VM metrics for Kubernetes
│   ├── checkin_listener.py     # Listener for remote check-ins
│   └── ssh_key_server.py       # Serves SSH public key over HTTPS
├── docs/                       # Additional documentation
│   ├── architecture.md         # Project architecture overview
│   └── setup-guide.md          # Detailed setup instructions
├── logs/                       # Runtime logs
│   ├── ansible.log             # Ansible execution logs
│   ├── k8s_metrics.log         # Kubernetes metrics logs
│   └── checkin.log             # Logs check-in data from remote PCs
├── vars/                       # Variable files
│   └── vault.yml               # Encrypted secrets (symlink to ansible/inventory/)
└── README.md                   # Main project README

'''
