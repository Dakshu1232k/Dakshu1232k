#!/bin/bash

# Update and install dependencies
sudo apt update
sudo apt install -y software-properties-common curl apt-transport-https ca-certificates gnupg

# Add PHP repository
sudo add-apt-repository -y ppa:ondrej/php

# Install PHP, MariaDB, Redis, and other necessary packages
sudo apt update
sudo apt install -y mariadb-server redis-server \
php8.0-cli php8.0-fpm php8.0-mysql php8.0-redis \
php8.0-mbstring php8.0-xml php8.0-bcmath php8.0-gd

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Set up Pterodactyl Panel container
docker run -d --name pterodactyl_panel \
-p 80:80 \
-p 443:443 \
-v /var/www/pterodactyl:/data \
pterodactyl/panel:latest

# Set up Wings (Pterodactyl Daemon)
docker run -d --name pterodactyl_wings \
-v /var/run/docker.sock:/var/run/docker.sock \
-v /etc/pterodactyl:/etc/pterodactyl \
-v /var/lib/pterodactyl:/var/lib/pterodactyl \
-p 8080:8080 \
pterodactyl/wings:latest

echo "Pterodactyl Panel and Wings installation is complete."
echo "Access the panel by visiting http://172.17.0.4"
