# File Structure - RHEL Ansible + Kubernetes Infrastructure for IT Support

Below is the complete file structure for the `rhel-ansible-k8s-it-support` repository, outlining directories and files used to manage remote PCs with Ansible and Kubernetes for MSP support.

```plaintext
rhel-ansible-k8s-it-support/
├── ansible/                    # Ansible configuration files
│   ├── inventory/              # Ansible inventory and secrets
│   │   ├── inventory.yml       # Main inventory file listing VMs
│   │   └── vault.yml           # Encrypted variables (e.g., Windows password)
│   ├── playbooks/              # Ansible playbooks for automation
│   │   ├── setup-ansible.yml   # Installs Ansible on RHEL 9 (optional)
│   │   ├── manage_vms.yml      # Basic VM management tasks
│   │   └── msp_support.yml     # Deploys MSP tools and collects metrics
│   └── roles/                  # Reusable Ansible roles
│       ├── monitoring/         # Role for monitoring setup
│       │   ├── tasks/          # Monitoring tasks
│       │   └── templates/      # Monitoring templates
│       └── patching/           # Role for VM patching
│           ├── tasks/          # Patching tasks
│           └── templates/      # Patching templates
├── kubernetes/                 # Kubernetes configuration files
│   ├── manifests/              # Kubernetes manifests for deployments
│   │   ├── prometheus.yml      # Deploys Prometheus for monitoring
│   │   ├── grafana.yml         # Deploys Grafana for visualization
│   │   └── osticket.yaml       # Deploys OSTicket for ticketing
│   └── scripts/                # Kubernetes setup scripts
│       └── setup-k8s.sh        # Installs Kubernetes on RHEL 9
├── deploy/                     # Scripts for control node deployment
│   ├── control-server.sh       # Deploys RHEL 9 server with Ansible + Kubernetes
│   └── control-workstation.sh  # Configures existing RHEL 9 workstation
├── remote_scripts/             # Scripts to connect remote PCs to control node
│   ├── rhel9_connect.sh        # Configures RHEL 9 remote PC
│   ├── windows_connect.ps1     # Configures Windows 11 Pro remote PC
│   ├── ubuntu_connect.sh       # Configures Ubuntu remote PC
│   ├── fedora_connect.sh       # Configures Fedora CoreOS remote PC
│   ├── install-agent.sh        # Generic agent setup script (future use)
│   └── README.md               # Documentation for remote scripts
├── scripts/                    # General utility scripts
│   ├── create-vm.ps1           # Creates Windows 11 VM (optional)
│   ├── precheck.sh             # Checks VM connectivity
│   ├── metrics_collector.sh    # Collects VM metrics for Kubernetes
│   ├── checkin_listener.py     # Listens for remote check-ins
│   └── ssh_key_server.py       # Serves SSH public key over HTTPS
├── docs/                       # Additional project documentation
│   ├── architecture.md         # Project architecture overview
│   └── setup-guide.md          # Detailed setup instructions
├── logs/                       # Runtime log files
│   ├── ansible.log             # Ansible execution logs
│   ├── k8s_metrics.log         # Kubernetes metrics logs
│   └── checkin.log             # Remote PC check-in logs
├── vars/                       # Variable files
│   └── vault.yml               # Encrypted secrets (symlink to ansible/inventory/)
└── README.md                   # Main project README
