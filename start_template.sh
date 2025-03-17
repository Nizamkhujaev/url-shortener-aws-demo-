#!/bin/bash

# ==================================================================================================
# 🚀 Automated Deployment Script for Node.js App on AWS EC2
# ==================================================================================================
# This script:
# ✅ Clones a private GitHub repo using HTTPS authentication
# ✅ Installs Node.js and dependencies
# ✅ Starts the app using PM2 for process management
# ✅ Configures Nginx as a reverse proxy to make the app publicly accessible
# ✅ Sets up SSL (Let's Encrypt) and domain configuration
# ==================================================================================================

set -e  # Exit script immediately if any command fails (useful for debugging)

# Define variables
GITHUB_USERNAME="your-username"      # Your GitHub username
GITHUB_REPO="your-private-repo"      # Your private repository name
GITHUB_TOKEN="your-github-token"     # Your GitHub personal access token for authentication
APP_DIR="/var/www/myapp"             # Directory where the app will be cloned
NODE_VERSION="18"                    # Node.js version to install
PORT=3000                             # Port where your app will run

# ========================================================================================
# 1️⃣ UPDATE SYSTEM & INSTALL REQUIRED DEPENDENCIES
# ========================================================================================
echo "Updating system packages..."
sudo dnf update -y  # Updates all system packages to their latest versions

echo "Installing required dependencies..."
sudo dnf install -y git curl nginx  # Installs Git (for repo cloning), Curl (for fetching URLs), and Nginx

# ========================================================================================
# 2️⃣ INSTALL NODE.JS
# ========================================================================================
echo "Installing Node.js..."
# Remove any existing Node.js versions
sudo dnf remove -y nodejs

# Add NodeSource repo for Node.js 18
curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -

# Install Node.js 18
sudo dnf install -y nodejs
# sudo dnf module enable -y nodejs:$NODE_VERSION  # Enables the Node.js module in dnf (Amazon Linux 2023)
# sudo dnf install -y nodejs  # Installs Node.js and npm

# ========================================================================================
# 3️⃣ CLONE OR UPDATE THE REPOSITORY
# ========================================================================================
if [ -d "$APP_DIR" ]; then
    echo "Repository already exists. Pulling latest changes..."
    cd "$APP_DIR"
    echo "Resetting local changes and pulling latest updates..."
    git reset --hard HEAD
    git pull origin main  # Pull latest changes from the remote repository
else
    echo "Cloning repository..."
    git clone https://$GITHUB_USERNAME:$GITHUB_TOKEN@github.com/$GITHUB_USERNAME/$GITHUB_REPO.git "$APP_DIR"
    cd "$APP_DIR"
fi

# ========================================================================================
# 4️⃣ INSTALL NODE.JS DEPENDENCIES
# ========================================================================================
echo "Installing Node.js dependencies..."
npm install  # Installs all required npm packages from package.json

# ========================================================================================
# 5️⃣ SET UP ENVIRONMENT VARIABLES
# ========================================================================================
if [ ! -f "$APP_DIR/.env" ]; then
    echo "No .env file found. Creating a default .env file..."
    cat <<EOT > "$APP_DIR/.env"
DB_USER=your_rds_username
DB_PASSWORD=your_rds_password
DB_HOST=your_rds_endpoint
DB_NAME=your_rds_database
DB_PORT=5432
PORT=$PORT
EOT
fi

# ========================================================================================
# 7️⃣ CONFIGURE NGINX AS A REVERSE PROXY
# ========================================================================================
# WHAT IS A REVERSE PROXY?
# ----------------------------------------
# A reverse proxy is a server that sits between client requests and backend servers.
# It forwards requests from users (clients) to the backend (our Node.js app).
#
# WHY USE A REVERSE PROXY?
# ✅ Security - Hides the backend server's IP & reduces exposure
# ✅ Performance - Can serve cached static content, reducing server load
# ✅ Scalability - Allows for load balancing multiple backend servers
# ✅ SSL Termination - Handles HTTPS requests, so the backend doesn't need SSL

echo "Configuring Nginx as a reverse proxy..."

# The "tee" command writes the configuration to the Nginx directory
# /dev/null discards the standard output (so it doesn’t clutter the terminal)
sudo tee /etc/nginx/conf.d/myapp.conf > /dev/null <<EOT
server {
    listen 80;  # Listen for HTTP traffic on port 80
    server_name your-domain.com;  # Replace with your domain name

    location / {
        proxy_pass http://localhost:$PORT;  # Forward requests to our Node.js app
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOT

# ========================================================================================
# 8️⃣ RESTART NGINX TO APPLY CHANGES
# ========================================================================================
echo "Restarting Nginx..."
sudo systemctl restart nginx  # Restarts Nginx with the new configuration
sudo systemctl enable nginx  # Enables Nginx to start automatically on system reboot

# ========================================================================================
# 6️⃣ START THE APPLICATION USING PM2
# ========================================================================================
echo "Starting the application with PM2..."
sudo npm install -g pm2  # Installs PM2 globally (process manager for Node.js)
pm2 stop all || true  # Stops any running instances (if they exist)
pm2 start src/index.js --name myapp  # Starts the application
pm2 save  # Saves the PM2 process list so it restarts after a reboot
pm2 startup systemd  # Ensures the app starts automatically on system boot



# ========================================================================================
# 9️⃣ ADDING SSL (HTTPS) & CUSTOM DOMAIN CONFIGURATION
# ========================================================================================
# HOW TO ADD SSL CERTIFICATE (Let's Encrypt)
# ------------------------------------------
# 🔹 This step makes your site accessible via HTTPS (secure).
# 🔹 It uses Let's Encrypt, a free SSL provider.
#
# Install Certbot (SSL certificate generator):
# sudo dnf install -y certbot python3-certbot-nginx
#
# Generate an SSL certificate:
# sudo certbot --nginx -d your-domain.com -d www.your-domain.com
#
# Automatically renew SSL certificates:
# sudo certbot renew --dry-run

# HOW TO ADD A CUSTOM DOMAIN
# ------------------------------------------
# 🔹 If you have a domain, point it to your EC2 instance via DNS settings.
# 🔹 Steps:
# 1. Buy a domain from Namecheap, GoDaddy, AWS Route 53, etc.
# 2. Update DNS records:
#    - Type: A
#    - Name: your-domain.com
#    - Value: your-ec2-public-ip
# 3. Modify Nginx config (above) to use your domain.

# ========================================================================================
# ✅ DEPLOYMENT COMPLETE
# ========================================================================================
echo "Deployment completed successfully! Your app is live."
echo "Access it at: http://your-ec2-public-ip/ or http://your-domain.com (if configured)"
