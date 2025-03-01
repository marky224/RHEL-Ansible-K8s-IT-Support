# Configs Folder

This folder contains configuration files for the Active Directory (AD) setup scripts in `AD-Setup`.

## Files
- **`dc_config.json`**: Main configuration file for AD deployment, including domain settings, OUs, network details, and more. Safe for public sharing as it excludes sensitive data.
- **`secrets.json`** (not included): Stores sensitive information like the Safe Mode Administrator Password. You must create this file locally.

## Usage
1. **Update `dc_config.json`**:
   - Edit this file with your environment-specific details (e.g., network IPs, storage paths) as needed.

2. **Create and Update `secrets.json`**:
   - Create a local `secrets.json` file in this folder with the following structure:
     ```json
     {
       "SafeModePassword": "YourComplexP@ssw0rd123!"
     }
     ```
   - Replace `"YourComplexP@ssw0rd123!"` with your actual password.
   - **Do not commit `secrets.json` to GitHub**. It’s excluded via `.gitignore` and should remain local to your machine or VM.

3. **Run Scripts**:
   - The AD setup scripts (e.g., `02-install-adds.ps1`) will read both `dc_config.json` and `secrets.json` to configure the Domain Controller.

## Notes
- Ensure `secrets.json` is stored securely and backed up outside of version control.
- Adjust `dc_config.json` storage paths (e.g., `D:\AD\Database`) to match your VMware disk layout.
