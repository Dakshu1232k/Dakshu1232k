#!/bin/bash

# Exit on any error
set -e

# Update system and install required packages
echo "Updating system and installing prerequisites..."
apt update && apt upgrade -y
apt install -y curl

# Install Docker
echo "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
rm get-docker.sh

# Enable and start Docker
systemctl enable docker
systemctl start docker

# Install Docker Compose
echo "Installing Docker Compose..."
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K[0-9.]+')
curl -L "https://github.com/docker/compose/releases/download/$DOCKER_COMPOSE_VERSION/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Create directory for Pterodactyl and navigate into it
echo "Setting up Pterodactyl directory..."
mkdir -p ~/pterodactyl-docker
cd ~/pterodactyl-docker

# Generate Docker Compose file
echo "Creating Docker Compose file for Pterodactyl..."
cat <<EOL > docker-compose.yml
version: '3'

services:
  panel:
    image: ghcr.io/pterodactyl/panel:latest
    environment:
      - DB_HOST=database
      - DB_PORT=3306
      - DB_DATABASE=pterodactyl
      - DB_USERNAME=pterodactyl
      - DB_PASSWORD=pterodactyl
      - APP_URL=http://138.68.79.95
    ports:
      - "80:80"
    depends_on:
      - database
    volumes:
      - ./data:/app

  database:
    image: mariadb:10.5
    environment:
      MYSQL_ROOT_PASSWORD: rootpassword
      MYSQL_DATABASE: pterodactyl
      MYSQL_USER: pterodactyl
      MYSQL_PASSWORD: yourpassword
    volumes:
      - ./mysql:/var/lib/mysql
EOL

# Replace placeholders with actual values
echo "Configuring environment variables..."
sed -i "s/yourpassword/$(openssl rand -base64 12)/g" docker-compose.yml
sed -i "s/rootpassword/$(openssl rand -base64 12)/g" docker-compose.yml
sed -i "s|http://your_server_ip|http://$(curl -s ifconfig.me)|g" docker-compose.yml

# Start Pterodactyl using Docker Compose
echo "Starting Pterodactyl..."
docker-compose up -d

echo "Pterodactyl has been installed and started!"
echo "Visit http://$(curl -s ifconfig.me) to complete the panel setup in your browser."
