@echo off
echo Setting static IP address to 192.168.10.135...

rem Set variables
set INTERFACE="Ethernet"
set IP_ADDRESS=192.168.10.135
set SUBNET_MASK=255.255.255.0
set GATEWAY=192.168.10.1
set DNS1=8.8.8.8
set DNS2=8.8.4.4

rem Configure static IP
netsh interface ip set address name=%INTERFACE% source=static addr=%IP_ADDRESS% mask=%SUBNET_MASK% gateway=%GATEWAY% gwmetric=1

rem Configure DNS servers
netsh interface ip set dns name=%INTERFACE% source=static addr=%DNS1%
netsh interface ip add dns name=%INTERFACE% addr=%DNS2% index=2

echo IP address and DNS settings applied.
echo Verifying configuration...
ipconfig /all

pause
