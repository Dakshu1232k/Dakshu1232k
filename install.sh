#!/bin/bash

# Update and upgrade system
echo "Updating the system..."
sudo apt update && sudo apt upgrade -y

# Install necessary dependencies
echo "Installing dependencies..."
sudo apt install -y curl apt-transport-https software-properties-common ca-certificates gnupg lsb-release

# Install Docker
echo "Installing Docker..."
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker

# Install Docker Compose
echo "Installing Docker Compose..."
sudo apt install -y docker-compose

# Install Nginx, MySQL, and PHP 8.1
echo "Installing Nginx, MySQL, and PHP 8.1..."
sudo apt install -y nginx mariadb-server mariadb-client php8.1-cli php8.1-fpm php8.1-mysql php8.1-zip php8.1-xml php8.1-mbstring php8.1-curl php8.1-gd composer unzip git

# Start and enable services
sudo systemctl start nginx
sudo systemctl enable nginx
sudo systemctl start mariadb
sudo systemctl enable mariadb

# Secure MySQL installation
echo "Securing MySQL installation..."
sudo mysql_secure_installation

# Create MySQL database and user for Pterodactyl
echo "Creating MySQL database and user..."
MYSQL_ROOT_PASSWORD="111_DAKU"
PTERO_DB_PASSWORD="111_DAKU"

sudo mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE DATABASE pterodactyl;"
sudo mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CREATE USER 'pterodactyl'@'127.0.0.1' IDENTIFIED BY '$PTERO_DB_PASSWORD';"
sudo mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON pterodactyl.* TO 'pterodactyl'@'127.0.0.1' WITH GRANT OPTION;"
sudo mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "FLUSH PRIVILEGES;"

# Clone Pterodactyl panel repository
echo "Cloning Pterodactyl panel repository..."
sudo git clone https://github.com/pterodactyl/panel.git /var/www/pterodactyl
cd /var/www/pterodactyl

# Install PHP dependencies
echo "Installing PHP dependencies..."
sudo composer install --no-dev --optimize-autoloader
cp .env.example .env
php artisan key:generate --force

# Update the .env file
echo "Updating the .env file..."
sed -i "s/DB_DATABASE=pterodactyl/DB_DATABASE=pterodactyl/" .env
sed -i "s/DB_USERNAME=pterodactyl/DB_USERNAME=pterodactyl/" .env
sed -i "s/DB_PASSWORD=/DB_PASSWORD=$PTERO_DB_PASSWORD/" .env

# Run migrations
echo "Running migrations..."
php artisan migrate --seed --force

# Set folder permissions
echo "Setting folder permissions..."
sudo chown -R www-data:www-data /var/www/pterodactyl
sudo chmod -R 755 /var/www/pterodactyl

# Create Nginx config for Pterodactyl
echo "Creating Nginx configuration for Pterodactyl..."
sudo tee /etc/nginx/sites-available/pterodactyl > /dev/null <<EOL
server {
    listen 80;
    server_name 172.17.0.4;
    root /var/www/pterodactyl/public;
    index index.php;

    access_log /var/log/nginx/pterodactyl.access.log;
    error_log  /var/log/nginx/pterodactyl.error.log error;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_split_path_info ^(.+\.php)(/.+)$;
        fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_param HTTP_PROXY "";
        fastcgi_intercept_errors off;
        fastcgi_buffer_size 16k;
        fastcgi_buffers 4 16k;
    }
}
EOL

# Enable the Nginx config and restart
sudo ln -s /etc/nginx/sites-available/pterodactyl /etc/nginx/sites-enabled/pterodactyl
sudo nginx -t
sudo systemctl restart nginx

# Install Wings
echo "Installing Pterodactyl Wings..."
curl -Lo /usr/local/bin/wings https://github.com/pterodactyl/wings/releases/latest/download/wings_linux_amd64
chmod +x /usr/local/bin/wings

# Create configuration directory for Wings
mkdir -p /etc/pterodactyl

# Start Wings
echo "Starting Wings..."
sudo wings --config /etc/pterodactyl/config.yml

# Optional: Enable SSL with Let's Encrypt
echo "Creating the admin user for Pterodactyl Panel..."

# Prompt for panel admin details
read -p "Enter admin email: " admin@gmail.com
read -p "Enter admin username: " admin
read -s -p "Enter admin password: " 111_DAKU
echo

# Run the artisan command to create the user
php artisan p:user:make <<EOF
$admin_email
$admin_username
$admin_password
admin
EOF

echo "Admin user created. You can now log in with $admin_email."
read -p "Do you want to enable SSL with Let's Encrypt? (y/n): " enable_ssl
if [ "$enable_ssl" = "y" ]; then
    sudo apt install -y certbot python3-certbot-nginx
    sudo certbot --nginx -d your_domain_or_ip
fi

echo "Pterodactyl Panel installation completed!"
echo "You can now access the panel at http://your_domain_or_ip"
echo "Make sure to update the following files for your specific setup:"

echo "
1. **MySQL Database Credentials:**
   File: /var/www/pterodactyl/.env
   Modify the 'DB_PASSWORD' and other details to match your database settings.

2. **NGINX Config:**
   File: /etc/nginx/sites-available/pterodactyl
   Update 'server_name' with your domain or IP address.

3. **SSL Setup (Optional):**
   If you enabled SSL, ensure you properly set up your DNS records to point to the correct domain."
