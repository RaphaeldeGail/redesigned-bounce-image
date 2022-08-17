#!/bin/bash

if [ -z "$RSA_KEY" ]; then
   echo "No private key RSA_KEY found"
   exit 1
fi

if [ -z "$RSA_PUB" ]; then
   echo "No public key RSA_KEY found"
   exit 1
fi

if [ -d /etc/custom ]; then
   sudo rm -rf /etc/custom
fi

sudo mkdir /etc/custom
sudo chmod 0700 /etc/custom

echo "Loading private key"
echo "$RSA_KEY" | base64 --decode | sudo tee /etc/custom/ssh_host_rsa_key > /dev/null
sudo chown root:root /etc/custom/ssh_host_rsa_key
sudo chmod 400 /etc/custom/ssh_host_rsa_key

echo "Loading public key"
echo "$RSA_PUB" | base64 --decode | sudo tee /etc/custom/ssh_host_rsa_key.pub > /dev/null
sudo chown root:root /etc/custom/ssh_host_rsa_key.pub
sudo chmod 600 /etc/custom/ssh_host_rsa_key.pub

echo "Building jail directory"
sudo mkdir -p /home/jail/dev
cd /home/jail/dev
sudo mknod -m 666 null c 1 3
sudo chown root:root /home/jail
sudo chmod 0755 /home/jail

echo "Loading configuration file"
echo -e "HostKey /etc/custom/ssh_host_rsa_key\nChrootDirectory /home/jail" | sudo tee /etc/ssh/sshd_config.d/custom.conf > /dev/null

if ! sudo test -f /etc/custom/ssh_host_rsa_key; then
   echo "private key /etc/custom/ssh_host_rsa_key was not correctly written"
   exit 1
fi
if ! sudo test -s /etc/custom/ssh_host_rsa_key; then
   echo "private key /etc/custom/ssh_host_rsa_key is empty"
   exit 1
fi
echo "Private key successfully loaded"

if ! sudo test -f /etc/custom/ssh_host_rsa_key.pub; then
   echo "Public key /etc/custom/ssh_host_rsa_key.pub was not correctly written"
   exit 1
fi
if ! sudo test -s /etc/custom/ssh_host_rsa_key.pub; then
   echo "Public key /etc/custom/ssh_host_rsa_key.pub is empty"
   exit 1
fi
echo "Public key successfully loaded"

if ! sudo test -f /etc/ssh/sshd_config.d/custom.conf; then
   echo "Configuration file /etc/ssh/sshd_config.d/custom.conf was not correctly written"
   exit 1
fi
if ! sudo test -s /etc/ssh/sshd_config.d/custom.conf; then
   echo "Configuration file /etc/ssh/sshd_config.d/custom.conf is empty"
   exit 1
fi
echo "Configuration file successfully loaded"

echo "Installing simple Nginx server"
sudo DEBIAN_FRONTEND=noninteractive apt-get --quiet update >/dev/null
sudo DEBIAN_FRONTEND=noninteractive apt-get --quiet -y install nginx >/dev/null

if ! systemctl is-active nginx > /dev/null; then
   echo "Nginx service is not active."
   exit 1
fi
echo "Nginx service is active."

if ! [ $(curl -s -o /dev/null -w '%{http_code}' 'http://127.0.0.1:80/') == 200 ]; then
   echo "Nginx server is not responding."
   exit 1
fi
echo "Nginx server is correctly responding."

# Disable APT sources
sudo apt-get --quiet clean >/dev/null
sudo rm -rf /etc/apt/sources.list /etc/apt/sources.list.d/

# Disable APT auto updates
echo -ne "APT::Periodic::Update-Package-Lists \"0\";\nAPT::Periodic::Unattended-Upgrade \"0\";" | sudo tee /etc/apt/apt.conf.d/20auto-upgrades > /dev/null
if ! sudo test -f /etc/apt/apt.conf.d/20auto-upgrades; then
   echo "Configuration file /etc/apt/apt.conf.d/20auto-upgrades was not correctly written."
   exit 1
fi
if ! sudo test -s /etc/apt/apt.conf.d/20auto-upgrades; then
   echo "Configuration file /etc/apt/apt.conf.d/20auto-upgrades is empty."
   exit 1
fi
echo "APT auto updates succesfully disabled."

echo "Build succesful"
exit 0