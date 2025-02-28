#!/bin/bash
# Run this on each Linux remote node
echo "Hostname: $(hostname -f)"
echo "IP: $(ip addr show | grep -o 'inet [0-9.]*' | awk '{print $2}' | head -n 1)"
echo "OS: $(cat /etc/redhat-release)"
echo "SSH User: $(whoami)"
echo "SSH Port: $(ss -tuln | grep :22 | awk '{print $5}' | cut -d: -f2 || echo '22')"
