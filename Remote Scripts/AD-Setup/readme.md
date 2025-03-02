# Configs Folder

This folder contains configuration files for the Active Directory (AD) setup scripts in `AD-Setup`.

## Files
- **`dc_config.json`**: Main configuration file for AD deployment, including domain settings, OUs, network details, and storage paths. This file is safe for public sharing as Sensitive data (e.g., passwords) is handled at runtime.

## Usage
1. **Update `dc_config.json`**:
   - Edit this file with your environment-specific details (e.g., network IPs, storage paths) as needed.
   - Default storage paths are set to `C:\AD\`—adjust if your VM uses multiple drives (e.g., `D:`, `E:`).

2. **Passwords**:
   - The Safe Mode Administrator password is prompted during script execution (e.g., `02-install-adds.ps1`). Save this password securely—it’s critical for DC recovery.
   - No separate `secrets.json` file is required; all sensitive data is entered at runtime.

3. **Run Scripts**:
   - Execute the AD setup scripts from the `scripts/` folder, providing passwords when prompted:
     ```powershell
     .\scripts\02-install-adds.ps1
     ```

## Notes
- Ensure your VM has at least 5 GB free on the `C:` drive (checked by `02-install-adds.ps1`).
- Update network settings (e.g., `192.168.10.0/24`) to match your VMware subnet if different.
