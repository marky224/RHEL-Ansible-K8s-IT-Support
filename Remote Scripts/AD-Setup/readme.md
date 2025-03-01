# AD-Setup

This folder contains PowerShell scripts and configurations for setting up an Active Directory (AD) Domain Controller on Windows Server 2025. It’s designed for an IT MSP environment, integrating with Ansible for initial node management and Kubernetes for production-grade orchestration.

## Purpose
- Deploy a secure, scalable AD DC for centralized authentication and DNS.
- Support Ansible control node and remote node configuration.
- Enable Kubernetes cluster integration via AD for RBAC and DNS.

## Usage
1. Edit `configs/dc_config.json` with your environment details.
2. Run scripts in sequence from the `scripts/` folder:
   ```powershell
   .\scripts\01-prepare.ps1 -ConfigPath "..\configs\dc_config.json"
