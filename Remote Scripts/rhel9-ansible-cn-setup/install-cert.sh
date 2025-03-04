#!/bin/bash
# install-cert.sh
# Script to install AD CS root certificate on Linux control node by pasting content

# Prompt user to paste the certificate
echo "Please paste the PEM-formatted AD CS root certificate below (including -----BEGIN CERTIFICATE----- and -----END CERTIFICATE-----)."
echo "Press Ctrl+D (Unix) or Ctrl+Z (Windows Subsystem for Linux) then Enter when finished:"
echo

# Read the pasted content into a variable
cert_content=$(cat)

# Check if content was provided
if [ -z "$cert_content" ]; then
    echo "Error: No certificate content provided."
    exit 1
fi

# Verify the content looks like a PEM certificate
if ! echo "$cert_content" | grep -q "-----BEGIN CERTIFICATE-----" || ! echo "$cert_content" | grep -q "-----END CERTIFICATE-----"; then
    echo "Error: Pasted content does not appear to be a valid PEM certificate."
    exit 1
fi

# Write the certificate to a temporary file
temp_file="/tmp/adcs_rootcert.pem"
echo "$cert_content" > "$temp_file"
if [ $? -ne 0 ]; then
    echo "Error: Failed to write certificate to temporary file $temp_file"
    exit 1
fi

# Copy certificate to ca-certificates directory
sudo cp "$temp_file" /usr/local/share/ca-certificates/adcs_rootcert.crt
if [ $? -ne 0 ]; then
    echo "Error: Failed to copy certificate to /usr/local/share/ca-certificates/"
    rm -f "$temp_file"
    exit 1
fi

# Clean up temporary file
rm -f "$temp_file"

# Update CA certificates
sudo update-ca-certificates
if [ $? -ne 0 ]; then
    echo "Error: Failed to update CA certificates"
    exit 1
fi

echo "Certificate installed and updated successfully in /usr/local/share/ca-certificates/adcs_rootcert.crt."
