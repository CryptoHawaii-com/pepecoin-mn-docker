#!/bin/bash

export DEBIAN_FRONTEND=noninteractive

print_status() {
    echo
    echo "## $1"
    echo
}

if [ $# -ne 1 ]; then
    echo "Execution format ./install.sh masternode_private_key"
    exit
fi

# Installation variables
privkey=${1}

rpcpassword=$(head -c 32 /dev/urandom | base64)

print_status "Installing the Pepecoin node..."

echo "#########################"
echo "Masternode Priv Key: $privkey"
echo "#########################"

# Create swapfile if less then 4GB memory
#totalm=$(free -m | awk '/^Mem:/{print $2}')
#if [ $totalm -lt 4000 ]; then
#  print_status "Server memory is less then 4GB..."
#  if ! grep -q '/swapfile' /etc/fstab ; then
#    print_status "Creating a 4GB swapfile..."
#    fallocate -l 4G /swapfile
#    chmod 600 /swapfile
#    mkswap /swapfile
#    swapon /swapfile
#    echo '/swapfile none swap sw 0 0' >> /etc/fstab
#  fi
#fi

# Populating Cache
#print_status "Populating apt-get cache..."
#apt-get update

#print_status "Installing packages required for setup..."
#apt-get install -y docker.io apt-transport-https lsb-release curl fail2ban unattended-upgrades ufw > /dev/null 2>&1

#systemctl enable docker
#systemctl start docker

print_status "Creating the docker mount directories..."
mkdir -p /mnt/pepecoin/config


print_status "Creating the pepecoin configuration."
cat <<EOF > /mnt/pepecoin/config/pepecoin.conf
rpcallowip=127.0.0.1
rpcuser=user
rpcpassword=$rpcpassword
server=1
# Docker doesn't run as daemon
daemon=0
listen=1
masternode=1
masternodeprivkey=$privkey
rpcport=29376
port=29377
addnode=seed1.pepe.org
addnode=seed2.pepe.org
addnode=seed3.pepe.org
EOF

print_status "Installing pepecoin service..."
cat <<EOF > /etc/systemd/system/pepecoind.service
[Unit]
Description=Pepecoin Daemon Container
After=docker.service
Requires=docker.service

[Service]
TimeoutStartSec=10m
Restart=always
ExecStartPre=-/usr/bin/docker stop pepecoind
ExecStartPre=-/usr/bin/docker rm  pepecoind
# Always pull the latest docker image
ExecStartPre=/usr/bin/docker pull rkurihara/pepecoind:latest
ExecStart=/usr/bin/docker run --rm --net=host -p 29377:29377 -v /mnt/pepecoin:/mnt/pepecoin --name pepecoind rkurihara/pepecoind:latest
[Install]
WantedBy=multi-user.target
EOF

print_status "Enabling and starting container services..."
systemctl daemon-reload
systemctl enable pepecoind
systemctl restart pepecoind

#print_status "Enabling basic firewall services..."
#ufw default allow outgoing
#ufw default deny incoming
#ufw allow ssh/tcp
#ufw limit ssh/tcp
#ufw allow 29377/tcp
#ufw --force enable

#print_status "Enabling fail2ban services..."
#systemctl enable fail2ban
#systemctl start fail2ban

#print_status "Waiting for node to fetch params ..."
#until docker exec -it zen-node /usr/local/bin/gosu user zen-cli getinfo
#do
#  echo ".."
#  sleep 30
#done

print_status "Install Finished"
echo "Please wait until the blocks are up to date..."

