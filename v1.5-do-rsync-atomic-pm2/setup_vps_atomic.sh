#!/bin/bash

# ---
# VPS Setup Script (Version 1.5: Atomic Deployment)
# Compatible with Ubuntu 20.04 / 22.04 / 24.04
# ---

set -e

echo "=================================================="
echo "   🚀 Atomic Server Setup"
echo "=================================================="

# 1. Inputs
read -p "🔹 Enter deploy username (e.g., deploy): " DEPLOY_USER
read -p "🔹 Enter domain name (e.g., example.com): " DOMAIN_NAME
read -p "🔹 Enter Node.js version (default 20): " NODE_VERSION
NODE_VERSION=${NODE_VERSION:-20}

# Ask about PR preview deployments
echo ""
read -p "🔹 Do you want to enable PR preview deployments? (y/n, default: n): " ENABLE_PREVIEW
ENABLE_PREVIEW=${ENABLE_PREVIEW:-n}

PREVIEW_DOMAIN=""
DNS_PROVIDER=""
if [[ "$ENABLE_PREVIEW" =~ ^[Yy]$ ]]; then
    read -p "🔹 Enter preview domain pattern (e.g., preview-{PORT}.example.com): " PREVIEW_DOMAIN
    read -p "🔹 DNS Provider for wildcard SSL (digitalocean/cloudflare, default: digitalocean): " DNS_PROVIDER
    DNS_PROVIDER=${DNS_PROVIDER:-digitalocean}
fi

# Ask about staging deployments
echo ""
read -p "🔹 Do you want to enable staging deployments? (y/n, default: n): " ENABLE_STAGING
ENABLE_STAGING=${ENABLE_STAGING:-n}

STAGING_DOMAIN=""
STAGING_PORT=""
if [[ "$ENABLE_STAGING" =~ ^[Yy]$ ]]; then
    read -p "🔹 Enter staging domain (e.g., staging.example.com): " STAGING_DOMAIN
    read -p "🔹 Enter staging port (e.g., 8001, default: 8001): " STAGING_PORT
    STAGING_PORT=${STAGING_PORT:-8001}
fi

echo ""

# 2. Updates & Essentials
apt update && apt upgrade -y
apt install -y curl git ufw nginx rsync certbot python3-certbot-nginx python3-certbot-dns-digitalocean python3-certbot-dns-cloudflare

# 3. Firewall
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw --force enable

# 4. User Setup
if ! id "$DEPLOY_USER" &>/dev/null; then
    useradd -m -s /bin/bash "$DEPLOY_USER"
    usermod -aG sudo "$DEPLOY_USER"
    passwd "$DEPLOY_USER"
fi

# 5. SSH Setup
USER_HOME="/home/$DEPLOY_USER"
mkdir -p "$USER_HOME/.ssh"
if [ -f /root/.ssh/authorized_keys ]; then
    cp /root/.ssh/authorized_keys "$USER_HOME/.ssh/authorized_keys"
fi

# Generate Action Key
KEY_PATH="$USER_HOME/.ssh/github_action_key"
if [ ! -f "$KEY_PATH" ]; then
    ssh-keygen -t ed25519 -f "$KEY_PATH" -N "" -C "github-atomic-deploy"
    cat "$KEY_PATH.pub" >> "$USER_HOME/.ssh/authorized_keys"
fi

chown -R "$DEPLOY_USER:$DEPLOY_USER" "$USER_HOME/.ssh"
chmod 700 "$USER_HOME/.ssh"
chmod 600 "$USER_HOME/.ssh/authorized_keys"
chmod 600 "$KEY_PATH"

# 6. Folder Structure (Crucial for Atomic)
echo "📂 Creating Atomic Folder Structure..."
APP_ROOT="$USER_HOME/app"
mkdir -p "$APP_ROOT/releases"
mkdir -p "$APP_ROOT/scripts"
# Create a dummy initial release so Nginx doesn't crash on first start
mkdir -p "$APP_ROOT/releases/initial/public"
ln -sfn "$APP_ROOT/releases/initial" "$APP_ROOT/current"

# Create preview builds directory if preview is enabled
if [[ "$ENABLE_PREVIEW" =~ ^[Yy]$ ]]; then
    echo "📁 Creating preview builds directory..."
    mkdir -p "$APP_ROOT/preview"
    chown -R "$DEPLOY_USER:$DEPLOY_USER" "$APP_ROOT/preview"
fi

# Create staging directory if staging is enabled
if [[ "$ENABLE_STAGING" =~ ^[Yy]$ ]]; then
    echo "📁 Creating staging directory..."
    mkdir -p "$APP_ROOT/staging"
    chown -R "$DEPLOY_USER:$DEPLOY_USER" "$APP_ROOT/staging"
fi

# Create the Switch Script
cat > "$APP_ROOT/scripts/atomic_switch.sh" <<EOF
#!/bin/bash
RELEASE_ID=\$1
APP_ROOT="$APP_ROOT"
NEW_RELEASE_PATH="\$APP_ROOT/releases/\$RELEASE_ID"

echo "🔄 Switching symlink..."
ln -sfn "\$NEW_RELEASE_PATH" "\$APP_ROOT/current"

echo "🚀 Reloading PM2..."
cd "\$APP_ROOT/current"
# Ensure ecosystem file exists or warn
if [ -f ecosystem.config.js ]; then
    pm2 reload ecosystem.config.js --update-env || pm2 start ecosystem.config.js
else
    echo "⚠️ No ecosystem file found yet. Skipping PM2 reload."
fi

echo "🧹 Cleanup..."
cd "\$APP_ROOT/releases"
# Only cleanup if there are more than 5 releases
if [ \$(ls -1t | wc -l) -gt 5 ]; then
    ls -1t | tail -n +6 | xargs -I {} rm -rf "{}"
fi
EOF

chmod +x "$APP_ROOT/scripts/atomic_switch.sh"
chown -R "$DEPLOY_USER:$DEPLOY_USER" "$USER_HOME/app"

# 7. Install Node & PM2
sudo -u "$DEPLOY_USER" bash <<EOF
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"
nvm install $NODE_VERSION
nvm use $NODE_VERSION
npm install -g pm2
EOF

# 8. Wildcard SSL Setup (if preview is enabled)
if [[ "$ENABLE_PREVIEW" =~ ^[Yy]$ ]]; then
    echo ""
    echo "=================================================="
    echo "🔐 Wildcard SSL Certificate Setup"
    echo "=================================================="
    echo "To enable PR preview deployments, you need a wildcard SSL certificate."
    echo ""
    
    if [[ "$DNS_PROVIDER" == "digitalocean" ]]; then
        echo "📋 Instructions for DigitalOcean API Token:"
        echo "   1. Log in to https://cloud.digitalocean.com"
        echo "   2. Go to API > Tokens/Keys"
        echo "   3. Click 'Generate New Token'"
        echo "   4. Give it a name (e.g., 'certbot-dns')"
        echo "   5. Make sure it has 'Read and Write' access"
        echo "   6. Copy the generated token"
        echo ""
        read -p "🔹 Enter your DigitalOcean API token: " DO_TOKEN
        
        # Create credentials file
        mkdir -p ~/.secrets/certbot
        cat > ~/.secrets/certbot/digitalocean.ini <<EOF
dns_digitalocean_token = $DO_TOKEN
EOF
        chmod 600 ~/.secrets/certbot/digitalocean.ini
        
        echo ""
        echo "🔐 Obtaining wildcard SSL certificate..."
        certbot certonly \
            --dns-digitalocean \
            --dns-digitalocean-credentials ~/.secrets/certbot/digitalocean.ini \
            -d "$DOMAIN_NAME" -d "*.$DOMAIN_NAME" \
            --non-interactive --agree-tos \
            --email "admin@$DOMAIN_NAME" || echo "⚠️ SSL certificate setup failed. You can run this manually later."
            
    elif [[ "$DNS_PROVIDER" == "cloudflare" ]]; then
        echo "📋 Instructions for Cloudflare API Token:"
        echo "   1. Log in to https://dash.cloudflare.com"
        echo "   2. Go to My Profile > API Tokens"
        echo "   3. Click 'Create Token'"
        echo "   4. Find 'Edit Zone DNS' template and click 'Use template'"
        echo "   5. Under 'Zone Resources', select your domain: $DOMAIN_NAME"
        echo "   6. Click 'Continue to summary', then 'Create Token'"
        echo "   7. Copy the generated token"
        echo ""
        read -p "🔹 Enter your Cloudflare API token: " CF_TOKEN
        
        # Create credentials file
        mkdir -p ~/.secrets/certbot
        cat > ~/.secrets/certbot/cloudflare.ini <<EOF
dns_cloudflare_api_token = $CF_TOKEN
EOF
        chmod 600 ~/.secrets/certbot/cloudflare.ini
        
        echo ""
        echo "🔐 Obtaining wildcard SSL certificate..."
        certbot certonly \
            --dns-cloudflare \
            --dns-cloudflare-credentials ~/.secrets/certbot/cloudflare.ini \
            -d "$DOMAIN_NAME" -d "*.$DOMAIN_NAME" \
            --non-interactive --agree-tos \
            --email "admin@$DOMAIN_NAME" || echo "⚠️ SSL certificate setup failed. You can run this manually later."
    fi
fi

# 9. Nginx Setup
# Point Nginx to the 'current' symlink
echo "🌐 Configuring Nginx..."

BASE_DOMAIN="$DOMAIN_NAME"
NGINX_CONFIG="/etc/nginx/sites-available/$DOMAIN_NAME"

# Build Nginx config
cat > "$NGINX_CONFIG" <<EOF
# Define a map to set the app port based on the host
map \$host \$app_port {
    default "";
    "$DOMAIN_NAME" 8000;
    "www.$DOMAIN_NAME" 8000;
EOF

# Add staging port mapping if enabled
if [[ "$ENABLE_STAGING" =~ ^[Yy]$ ]]; then
    cat >> "$NGINX_CONFIG" <<EOF
    "$STAGING_DOMAIN" $STAGING_PORT;
EOF
fi

# Add preview port mapping if enabled
if [[ "$ENABLE_PREVIEW" =~ ^[Yy]$ ]]; then
    cat >> "$NGINX_CONFIG" <<EOF
    "~^preview-([0-9]+)\\.$DOMAIN_NAME\$" \$1;
EOF
fi

cat >> "$NGINX_CONFIG" <<EOF
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;
EOF

# Add staging and preview domains to HTTP redirect
if [[ "$ENABLE_STAGING" =~ ^[Yy]$ ]]; then
    cat >> "$NGINX_CONFIG" <<EOF
    server_name $STAGING_DOMAIN;
EOF
fi

if [[ "$ENABLE_PREVIEW" =~ ^[Yy]$ ]]; then
    cat >> "$NGINX_CONFIG" <<EOF
    server_name preview-*.$DOMAIN_NAME;
EOF
fi

cat >> "$NGINX_CONFIG" <<EOF

    # Redirect all HTTP requests to HTTPS
    location / {
        return 301 https://\$host\$request_uri;
    }
}

# HTTPS server block
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;
EOF

# Add staging and preview domains to HTTPS server
if [[ "$ENABLE_STAGING" =~ ^[Yy]$ ]]; then
    cat >> "$NGINX_CONFIG" <<EOF
    server_name $STAGING_DOMAIN;
EOF
fi

if [[ "$ENABLE_PREVIEW" =~ ^[Yy]$ ]]; then
    cat >> "$NGINX_CONFIG" <<EOF
    server_name preview-*.$DOMAIN_NAME;
EOF
fi

# SSL configuration
if [[ "$ENABLE_PREVIEW" =~ ^[Yy]$ ]] && [ -f "/etc/letsencrypt/live/$BASE_DOMAIN/fullchain.pem" ]; then
    cat >> "$NGINX_CONFIG" <<EOF

    # SSL configuration (wildcard certificate)
    ssl_certificate /etc/letsencrypt/live/$BASE_DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$BASE_DOMAIN/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/$BASE_DOMAIN/chain.pem;

    # SSL settings for better security
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers HIGH:!aNULL:!MD5;
EOF
else
    cat >> "$NGINX_CONFIG" <<EOF

    # SSL configuration (will be added by certbot)
    # ssl_certificate /etc/letsencrypt/live/$BASE_DOMAIN/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/$BASE_DOMAIN/privkey.pem;
EOF
fi

cat >> "$NGINX_CONFIG" <<EOF

    # Point root to the public folder inside 'current'
    root $APP_ROOT/current/public;

    # Define DNS resolver for Nginx
    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;
    
    client_max_body_size 10M;

    location / {
        # If no valid port is set, return 404 Not Found
        if (\$app_port = "") {
            return 404;
        }

        # Proxy configuration
        proxy_pass http://127.0.0.1:\$app_port;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Nginx-Proxy true;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        
        # Enable Streaming
        chunked_transfer_encoding on;
        proxy_buffering off;
        
        # Enable caching and revalidation for upstream servers
        proxy_cache_use_stale error timeout invalid_header updating http_500 http_502 http_503 http_504;
        proxy_cache_lock on;
    }
}
EOF

ln -sf "$NGINX_CONFIG" /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

# Test Nginx config
if nginx -t; then
    systemctl reload nginx
    echo "✅ Nginx configuration updated successfully"
else
    echo "⚠️ Nginx configuration test failed. Please check the config manually."
fi

# 10. Final Output
PRIVATE_KEY=$(cat "$KEY_PATH")

echo ""
echo "=================================================="
echo "✅ ATOMIC SETUP COMPLETE!"
echo "=================================================="
echo "👉 Add these secrets to your GitHub Repo:"
echo "   DROPLET_IP:   $(curl -s ifconfig.me)"
echo "   DROPLET_USER: $DEPLOY_USER"
if [[ "$ENABLE_PREVIEW" =~ ^[Yy]$ ]]; then
    echo "   DOMAIN_NAME: $DOMAIN_NAME (required for preview deployments)"
fi
echo "   SSH_PRIVATE_KEY: (Copy the block below)"
echo "--------------------------------------------------"
echo "$PRIVATE_KEY"
echo "--------------------------------------------------"
echo ""

if [[ "$ENABLE_PREVIEW" =~ ^[Yy]$ ]]; then
    echo "👉 PR Preview Configuration:"
    echo "   Preview Domain Pattern: $PREVIEW_DOMAIN"
    echo "   Port Range: 8500-8999 (based on PR number)"
    echo ""
fi

if [[ "$ENABLE_STAGING" =~ ^[Yy]$ ]]; then
    echo "👉 Staging Configuration:"
    echo "   Staging Domain: $STAGING_DOMAIN"
    echo "   Staging Port: $STAGING_PORT"
    echo ""
fi

echo "👉 SSL SETUP:"
if [[ "$ENABLE_PREVIEW" =~ ^[Yy]$ ]] && [ -f "/etc/letsencrypt/live/$BASE_DOMAIN/fullchain.pem" ]; then
    echo "   ✅ Wildcard SSL certificate installed"
else
    echo "   1. For Standard SSL ($DOMAIN_NAME):"
    echo "      Run: sudo certbot --nginx -d $DOMAIN_NAME"
    echo ""
    echo "   2. For Wildcard SSL (*.$DOMAIN_NAME):"
    if [[ "$DNS_PROVIDER" == "digitalocean" ]]; then
        echo "      Run: sudo certbot certonly --dns-digitalocean --dns-digitalocean-credentials ~/.secrets/certbot/digitalocean.ini -d $DOMAIN_NAME -d *.$DOMAIN_NAME"
    elif [[ "$DNS_PROVIDER" == "cloudflare" ]]; then
        echo "      Run: sudo certbot certonly --dns-cloudflare --dns-cloudflare-credentials ~/.secrets/certbot/cloudflare.ini -d $DOMAIN_NAME -d *.$DOMAIN_NAME"
    fi
fi
echo "=================================================="
