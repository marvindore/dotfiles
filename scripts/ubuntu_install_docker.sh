#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

echo "--- Starting Docker Installation ---"

# 1. Update and Upgrade System
echo "Updating and upgrading system packages..."
sudo apt update && sudo apt upgrade -y

# 2. Install prerequisites
echo "Installing prerequisites (ca-certificates, curl)..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl

# 3. Set up Docker's GPG key
echo "Setting up Docker GPG key..."
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# 4. Add the repository to Apt sources
echo "Adding Docker repository to Apt sources..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 5. Update the package index
echo "Updating package index..."
sudo apt-get update

# 6. Install Docker engine and plugins
echo "Installing Docker Engine, CLI, and plugins..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "--- Docker installation complete! ---"
echo "You can verify the installation by running: sudo docker run hello-world"
