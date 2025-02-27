rhel9-ansible-k8s-msp/
├── ansible/                    # Ansible-related files
│   ├── inventory/              # Inventory files for Ansible
│   │   ├── inventory.yml       # Main inventory file for VMs
│   │   └── vault.yml           # Encrypted variables (e.g., Windows password)
│   ├── playbooks/              # Ansible playbooks
│   │   ├── setup-ansible.yml   # Installs Ansible on RHEL 9 (optional)
│   │   ├── manage_vms.yml      # Basic VM management tasks
│   │   └── msp_support.yml     # Deploys MSP tools and collects metrics
│   └── roles/                  # Reusable Ansible roles
│       ├── monitoring/         # Role for monitoring setup
│       │   ├── tasks/
│       │   └── templates/
│       └── patching/           # Role for VM patching
│           ├── tasks/
│           └── templates/
├── kubernetes/                 # Kubernetes-related files
│   ├── manifests/              # Kubernetes manifests
│   │   ├── prometheus.yml      # Prometheus deployment
│   │   ├── grafana.yml         # Grafana deployment
│   │   └── osticket.yaml       # OSTicket deployment
│   └── scripts/                # Kubernetes setup scripts
│       └── setup-k8s.sh        # Script to install Kubernetes on RHEL 9
├── scripts/                    # General utility scripts
│   ├── create-vm.ps1           # PowerShell script to create Windows 11 VM (optional)
│   ├── precheck.sh             # Pre-check script for VM connectivity
│   └── metrics_collector.sh    # Script to collect VM metrics for Kubernetes
├── docs/                       # Documentation
│   ├── architecture.md         # Project architecture overview
│   └── setup-guide.md          # Detailed setup instructions
├── logs/                       # Log files (generated at runtime)
│   ├── ansible.log             # Ansible execution logs
│   └── k8s_metrics.log         # Kubernetes metrics logs
├── vars/                       # Variable files
│   └── vault.yml               # Encrypted secrets (symlink to ansible/inventory/)
└── README.md                   # Project README
