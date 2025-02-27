# Scripts Directory

This directory contains utility scripts for the `RHEL-Ansible-K8s-IT-Support` project, supporting Ansible and Kubernetes automation on RHEL 9 systems.

## Files

- **`checkin_listener.py`**
  - **Purpose**: An HTTPS server that listens for POST requests from remote nodes checking in after configuration.
  - **Functionality**: Logs check-in data (e.g., hostname, IP, OS) to `/var/log/checkin.log` and responds with "Check-in received".
  - **Usage**: Run via `systemd` on the control node (`192.168.10.100`) at port 8080 (configurable).
  - **Arguments**: `--port <port>`, `--cert <cert_path>`, `--key <key_path>`.

- **`ssh_key_server.py`**
  - **Purpose**: An HTTPS server that serves the control node’s SSH public key to remote nodes during setup.
  - **Functionality**: Responds to GET requests at `/ssh_key` with the contents of `/root/.ssh/id_rsa.pub`.
  - **Usage**: Run via `systemd` on the control node at port 8080 (configurable).
  - **Arguments**: `--port <port>`, `--cert <cert_path>`, `--key <key_path>`.

- **`create-vm.ps1`**
  - **Purpose**: Creates a Windows 11 VM (optional utility).
  - **Usage**: Run on a Windows host with VMware Workstation.

- **`precheck.sh`**
  - **Purpose**: Checks connectivity to VMs before Ansible tasks.
  - **Usage**: Run on the control node.

- **`metrics_collector.sh`**
  - **Purpose**: Collects VM metrics for Kubernetes monitoring.
  - **Usage**: Run on the control node or remote nodes.

## Installation
These scripts are downloaded to `/usr/local/bin/` by `deploy/control-server.sh` from this GitHub repository during control node setup. Ensure they are present in the `scripts/` directory before running the deployment script.

## Requirements
- Python 3 (for `.py` scripts)
- OpenSSL (for HTTPS certificate handling)
- Internet access (for GitHub downloads)

## Notes
- Update `checkin_listener.py` and `ssh_key_server.py` in this directory to add features like token authentication or additional endpoints.
- Logs for `checkin_listener.py` are stored in `/var/log/checkin.log` on the control node.
