#!/bin/bash

# Disable laptop lock by closing the lid
sed -i "s/^#HandleLidSwitch=.*/HandleLidSwitch=ignore/" /etc/systemd/logind.conf
systemctl restart systemd-logind

# Update APT
apt update
apt install -y ca-certificates curl

# Add the official Docker GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add the Docker repository to APT sources
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update repositories and install Docker
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Create Docker Group and add current user
groupadd docker
usermod -aG docker "$USER"

# Enable autostart of Docker and containerd
systemctl enable docker.service
systemctl enable containerd.service

# Run docker compose to start the services
docker compose up -d

# Install NFS
apt install -y nfs-kernel-server

# Create directory to share "nfs_share"
mkdir -p /srv/nfs_share
chown -R nobody:nogroup /srv/nfs_share
chmod -R 640 /srv/nfs_share

# Configure exports for NFS
echo "/srv/nfs_share  192.168.0.0/24(rw,sync,no_subtree_check)" >> /etc/exports

# Export the files and restart the NFS service
exportfs -a
systemctl restart nfs-kernel-server

if [ $? -eq 0 ]; then
    # If no errors, clear the screen and show the final message
    clear
    SERVER_IP=$(hostname -I | awk '{print $1}')
    echo "----------------------------------------------------------"
    echo "Server configuration completed successfully"
    echo ""
    echo "You can access Portainer at https://$SERVER_IP:9443"
    echo "You can access AdGuard Home at http://$SERVER_IP:3000"
    echo "You can access NFS at \\$SERVER_IP\srv\nfs_share"
    echo "----------------------------------------------------------"
else
    # If there was an error, display an error message
    echo "There was an error during the server configuration. Please check the previous output in the terminal."
    exit 1
fi
