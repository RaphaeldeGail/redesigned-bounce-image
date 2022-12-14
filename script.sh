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
   rm -rf /etc/custom
fi

mkdir /etc/custom
chmod 0700 /etc/custom

echo "Loading private key"
echo "$RSA_KEY" | base64 --decode > /etc/custom/ssh_host_rsa_key
chown root:root /etc/custom/ssh_host_rsa_key
chmod 400 /etc/custom/ssh_host_rsa_key

echo "Loading public key"
echo "$RSA_PUB" | base64 --decode > /etc/custom/ssh_host_rsa_key.pub
chown root:root /etc/custom/ssh_host_rsa_key.pub
chmod 600 /etc/custom/ssh_host_rsa_key.pub

echo "Building jail directory"
mkdir -p /home/jail/dev
cd /home/jail/dev
mknod -m 666 null c 1 3
chown root:root /home/jail
chmod 0755 /home/jail
cd -

echo "Loading configuration file."
echo -e "HostKey /etc/custom/ssh_host_rsa_key\nChrootDirectory /home/jail" > /etc/ssh/sshd_config.d/custom.conf

if ! test -s /etc/custom/ssh_host_rsa_key; then
   echo "private key /etc/custom/ssh_host_rsa_key was not correctly written."
   exit 1
fi
echo "Private key successfully loaded."

if ! test -s /etc/custom/ssh_host_rsa_key.pub; then
   echo "Public key /etc/custom/ssh_host_rsa_key.pub was not correctly written."
   exit 1
fi
echo "Public key successfully loaded."

if ! test -s /etc/ssh/sshd_config.d/custom.conf; then
   echo "Configuration file /etc/ssh/sshd_config.d/custom.conf was not correctly written."
   exit 1
fi
echo "Configuration file successfully loaded."

echo "Testing if public and private SSH keys match."
if ! [ "$(ssh-keygen -l -E sha256 -f /etc/custom/ssh_host_rsa_key)"=="$(ssh-keygen -l -E sha256 -f /etc/custom/ssh_host_rsa_key.pub)" ]; then
   echo "Public and private keys do not match."
   exit 1
fi
echo "Public and private keys match perfectly."

echo "Tesing SSHD server configuration."
if ! sshd -t; then
   echo "SSHD server configuration is not valid."
   exit 1
fi
echo "SSHD server configuration is fully valid."

echo "Installing simple Nginx server."
DEBIAN_FRONTEND=noninteractive apt-get --quiet update >/dev/null
DEBIAN_FRONTEND=noninteractive apt-get --quiet -y install nginx >/dev/null

if ! systemctl is-active nginx > /dev/null; then
   echo "Nginx service is not active."
   exit 1
fi
echo "Nginx service is active."

if ! [ $(curl -s -o /dev/null -w '%{http_code}' 'http://127.0.0.1:80/') == 200 ]; then
   echo "Nginx HTTP service is not responding."
   exit 1
fi
echo "Nginx HTTP service is correctly responding."

# Disable APT sources
echo "Removing APT packages cache and lists."
apt-get --quiet clean >/dev/null
rm -rf /etc/apt/sources.list /etc/apt/sources.list.d/

# Disable APT auto updates
echo "Loading APT configuration to halt auto-update."
echo -ne "APT::Periodic::Update-Package-Lists \"0\";\nAPT::Periodic::Unattended-Upgrade \"0\";" > /etc/apt/apt.conf.d/20auto-upgrades
if ! test -s /etc/apt/apt.conf.d/20auto-upgrades; then
   echo "Configuration file /etc/apt/apt.conf.d/20auto-upgrades was not correctly written."
   exit 1
fi
echo "APT auto-update succesfully disabled."

echo -ne "\nBuild was succesful.\n"
exit 0