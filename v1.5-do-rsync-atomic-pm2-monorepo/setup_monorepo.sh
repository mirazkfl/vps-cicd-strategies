#!/bin/bash

# ---
# Monorepo VPS Setup Script (Version 1.5: Atomic Deployment)
# Supports: Multiple Apps on One Server with Atomic Deployments
# Compatible with Ubuntu 20.04 / 22.04 / 24.04
# ---

set -e

echo "=================================================="
echo "   🏰 Monorepo Server Setup (Version 1.5 Atomic)"
echo "=================================================="

# 1. Global Setup (Run once, checks if user exists)
read -p "🔹 Enter global deploy username (e.g., deploy): " DEPLOY_USER

GLOBAL_PREVIEW_SETUP=false
BASE_DOMAIN=""
DNS_PROVIDER=""

if ! id "$DEPLOY_USER" &>/dev/null; then
    echo "👤 Creating user $DEPLOY_USER..."
    useradd -m -s /bin/bash "$DEPLOY_USER"
    usermod -aG sudo "$DEPLOY_USER"
    
    echo "⚠️ Set a password for $DEPLOY_USER:"
    passwd "$DEPLOY_USER"
    
    # 2. System Updates & Essentials (only on first run)
    echo "📦 Updating system..."
    apt update && apt upgrade -y
    apt install -y curl git ufw nginx rsync certbot python3-certbot-nginx python3-certbot-dns-digitalocean python3-certbot-dns-cloudflare
    
    # 3. Security (Firewall) - only configure once
    echo "🛡️ Configuring Firewall..."
    ufw allow OpenSSH
    ufw allow 'Nginx Full'
    ufw --force enable
    
    # 4. SSH Setup for new user
    USER_HOME="/home/$DEPLOY_USER"
    mkdir -p "$USER_HOME/.ssh"
    
    # Copy root's allowed keys to new user so you can log in immediately
    if [ -f /root/.ssh/authorized_keys ]; then
        cp /root/.ssh/authorized_keys "$USER_HOME/.ssh/authorized_keys"
    fi
    
    # Generate a Deploy Key for GitHub Actions (only once)
    KEY_PATH="$USER_HOME/.ssh/github_action_key"
    if [ ! -f "$KEY_PATH" ]; then
        ssh-keygen -t ed25519 -f "$KEY_PATH" -N "" -C "github-atomic-deploy"
        cat "$KEY_PATH.pub" >> "$USER_HOME/.ssh/authorized_keys"
    fi
    
    # Fix permissions
    chown -R "$DEPLOY_USER:$DEPLOY_USER" "$USER_HOME/.ssh"
    chmod 700 "$USER_HOME/.ssh"
    chmod 600 "$USER_HOME/.ssh/authorized_keys"
    chmod 600 "$KEY_PATH"
    
    # 5. Install Node/PM2 (as the user) - only once
    read -p "🔹 Enter Node.js version (default 20): " NODE_VERSION
    NODE_VERSION=${NODE_VERSION:-20}
    
    echo "🟢 Installing Node.js & PM2..."
    sudo -u "$DEPLOY_USER" bash <<EOF
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"
nvm install $NODE_VERSION
nvm use $NODE_VERSION
nvm alias default $NODE_VERSION
npm install -g pm2
EOF
    
    # Ask about PR preview deployments (global, once)
    echo ""
    read -p "🔹 Do you want to enable PR preview deployments? (y/n, default: n): " ENABLE_PREVIEW
    ENABLE_PREVIEW=${ENABLE_PREVIEW:-n}
    
    if [[ "$ENABLE_PREVIEW" =~ ^[Yy]$ ]]; then
        read -p "🔹 Enter base domain for previews (e.g., example.com): " BASE_DOMAIN
        read -p "🔹 DNS Provider for wildcard SSL (digitalocean/cloudflare, default: digitalocean): " DNS_PROVIDER
        DNS_PROVIDER=${DNS_PROVIDER:-digitalocean}
        GLOBAL_PREVIEW_SETUP=true
        
        # Create preview builds directory
        mkdir -p "$USER_HOME/apps/preview"
        chown -R "$DEPLOY_USER:$DEPLOY_USER" "$USER_HOME/apps/preview"
        
        # Setup wildcard SSL
        echo ""
        echo "=================================================="
        echo "🔐 Wildcard SSL Certificate Setup"
        echo "=================================================="
        
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
                -d "$BASE_DOMAIN" -d "*.$BASE_DOMAIN" \
                --non-interactive --agree-tos \
                --email "admin@$BASE_DOMAIN" || echo "⚠️ SSL certificate setup failed. You can run this manually later."
                
        elif [[ "$DNS_PROVIDER" == "cloudflare" ]]; then
            echo "📋 Instructions for Cloudflare API Token:"
            echo "   1. Log in to https://dash.cloudflare.com"
            echo "   2. Go to My Profile > API Tokens"
            echo "   3. Click 'Create Token'"
            echo "   4. Find 'Edit Zone DNS' template and click 'Use template'"
            echo "   5. Under 'Zone Resources', select your domain: $BASE_DOMAIN"
            echo "   6. Click 'Continue to summary', then 'Create Token'"
            echo "   7. Copy the generated token"
            echo ""
            read -p "🔹 Enter your Cloudflare API token: " CF_TOKEN
            
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
                -d "$BASE_DOMAIN" -d "*.$BASE_DOMAIN" \
                --non-interactive --agree-tos \
                --email "admin@$BASE_DOMAIN" || echo "⚠️ SSL certificate setup failed. You can run this manually later."
        fi
    fi
    
    echo "✅ Global setup complete for user $DEPLOY_USER"
else
    echo "✅ User $DEPLOY_USER already exists. Proceeding with app-specific setup..."
    USER_HOME="/home/$DEPLOY_USER"
fi

# 6. App-Specific Setup
echo "--------------------------------------------------"
echo "Now configuring a specific application..."
read -p "🔹 App Name (matches folder in repo, e.g., 'web' or 'admin'): " APP_NAME
read -p "🔹 Domain for this app (e.g., app.example.com): " DOMAIN_NAME
read -p "🔹 Port for this app (e.g., 3000 for web, 3001 for admin): " APP_PORT

# Ask about staging for this app
read -p "🔹 Do you want staging deployment for this app? (y/n, default: n): " ENABLE_STAGING
ENABLE_STAGING=${ENABLE_STAGING:-n}

STAGING_DOMAIN=""
STAGING_PORT=""
if [[ "$ENABLE_STAGING" =~ ^[Yy]$ ]]; then
    read -p "🔹 Enter staging domain (e.g., staging-app.example.com): " STAGING_DOMAIN
    read -p "🔹 Enter staging port (e.g., 8001, default: 8001): " STAGING_PORT
    STAGING_PORT=${STAGING_PORT:-8001}
    
    # Create staging directory
    mkdir -p "$USER_HOME/apps/$APP_NAME/staging"
    chown -R "$DEPLOY_USER:$DEPLOY_USER" "$USER_HOME/apps/$APP_NAME/staging"
fi

# 7. Create Atomic Folder Structure
APP_ROOT="/home/$DEPLOY_USER/apps/$APP_NAME"
echo "📂 Creating Atomic Folder Structure for $APP_NAME..."
mkdir -p "$APP_ROOT/releases"
mkdir -p "$APP_ROOT/scripts"
# Create a dummy initial release so Nginx doesn't crash on first start
mkdir -p "$APP_ROOT/releases/initial/public"
ln -sfn "$APP_ROOT/releases/initial" "$APP_ROOT/current"

# Create the Switch Script for this app
cat > "$APP_ROOT/scripts/atomic_switch.sh" <<EOF
#!/bin/bash
RELEASE_ID=\$1
APP_ROOT="$APP_ROOT"
NEW_RELEASE_PATH="\$APP_ROOT/releases/\$RELEASE_ID"

echo "🔄 Switching symlink for $APP_NAME..."
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
chown -R "$DEPLOY_USER:$DEPLOY_USER" "/home/$DEPLOY_USER/apps"

# 8. Nginx Config
echo "🌐 Configuring Nginx for $APP_NAME..."

NGINX_CONFIG="/etc/nginx/sites-available/$DOMAIN_NAME"

# Build Nginx config with support for preview and staging
cat > "$NGINX_CONFIG" <<EOF
# Define a map to set the app port based on the host
map \$host \$app_port {
    default "";
    "$DOMAIN_NAME" $APP_PORT;
    "www.$DOMAIN_NAME" $APP_PORT;
EOF

# Add staging port mapping if enabled
if [[ "$ENABLE_STAGING" =~ ^[Yy]$ ]]; then
    cat >> "$NGINX_CONFIG" <<EOF
    "$STAGING_DOMAIN" $STAGING_PORT;
EOF
fi

# Add preview port mapping if global preview is enabled
if [[ "$GLOBAL_PREVIEW_SETUP" == true ]]; then
    cat >> "$NGINX_CONFIG" <<EOF
    "~^preview-([0-9]+)\\.$BASE_DOMAIN\$" \$1;
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

if [[ "$ENABLE_STAGING" =~ ^[Yy]$ ]]; then
    cat >> "$NGINX_CONFIG" <<EOF
    server_name $STAGING_DOMAIN;
EOF
fi

if [[ "$GLOBAL_PREVIEW_SETUP" == true ]]; then
    cat >> "$NGINX_CONFIG" <<EOF
    server_name preview-*.$BASE_DOMAIN;
EOF
fi

cat >> "$NGINX_CONFIG" <<EOF

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

if [[ "$ENABLE_STAGING" =~ ^[Yy]$ ]]; then
    cat >> "$NGINX_CONFIG" <<EOF
    server_name $STAGING_DOMAIN;
EOF
fi

if [[ "$GLOBAL_PREVIEW_SETUP" == true ]]; then
    cat >> "$NGINX_CONFIG" <<EOF
    server_name preview-*.$BASE_DOMAIN;
EOF
fi

# SSL configuration
if [[ "$GLOBAL_PREVIEW_SETUP" == true ]] && [ -f "/etc/letsencrypt/live/$BASE_DOMAIN/fullchain.pem" ]; then
    cat >> "$NGINX_CONFIG" <<EOF

    ssl_certificate /etc/letsencrypt/live/$BASE_DOMAIN/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$BASE_DOMAIN/privkey.pem;
    ssl_trusted_certificate /etc/letsencrypt/live/$BASE_DOMAIN/chain.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers HIGH:!aNULL:!MD5;
EOF
else
    cat >> "$NGINX_CONFIG" <<EOF

    # SSL configuration (will be added by certbot)
    # ssl_certificate /etc/letsencrypt/live/$DOMAIN_NAME/fullchain.pem;
    # ssl_certificate_key /etc/letsencrypt/live/$DOMAIN_NAME/privkey.pem;
EOF
fi

cat >> "$NGINX_CONFIG" <<EOF

    # Point root to the public folder inside 'current'
    root $APP_ROOT/current/public;

    resolver 8.8.8.8 8.8.4.4 valid=300s;
    resolver_timeout 5s;
    client_max_body_size 10M;

    location / {
        if (\$app_port = "") {
            return 404;
        }

        proxy_pass http://127.0.0.1:\$app_port;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header X-Nginx-Proxy true;
        proxy_http_version 1.1;
        proxy_set_header Connection "";
        chunked_transfer_encoding on;
        proxy_buffering off;
        proxy_cache_use_stale error timeout invalid_header updating http_500 http_502 http_503 http_504;
        proxy_cache_lock on;
    }
}
EOF

ln -sf "$NGINX_CONFIG" /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

if nginx -t; then
    systemctl reload nginx
    echo "✅ Nginx configuration updated successfully"
else
    echo "⚠️ Nginx configuration test failed. Please check the config manually."
fi

# 9. Final Output
if [ -f "$USER_HOME/.ssh/github_action_key" ]; then
    PRIVATE_KEY=$(cat "$USER_HOME/.ssh/github_action_key")
    
    echo ""
    echo "=================================================="
    echo "✅ Atomic Setup for '$APP_NAME' complete!"
    echo "=================================================="
    echo "   - Deploy Path: $APP_ROOT"
    echo "   - Releases: $APP_ROOT/releases"
    echo "   - Current Symlink: $APP_ROOT/current"
    echo "   - URL: http://$DOMAIN_NAME"
    echo "   - Port: $APP_PORT"
    if [[ "$ENABLE_STAGING" =~ ^[Yy]$ ]]; then
        echo "   - Staging: $STAGING_DOMAIN (Port: $STAGING_PORT)"
    fi
    echo ""
    echo "👉 GitHub Secrets (if not already added):"
    echo "   DROPLET_IP:   $(curl -s ifconfig.me)"
    echo "   DROPLET_USER: $DEPLOY_USER"
    echo "   SSH_PRIVATE_KEY: (Copy the block below)"
    echo "--------------------------------------------------"
    echo "$PRIVATE_KEY"
    echo "--------------------------------------------------"
    if [[ "$GLOBAL_PREVIEW_SETUP" == true ]]; then
        echo ""
        echo "👉 PR Preview Configuration:"
        echo "   Base Domain: $BASE_DOMAIN"
        echo "   Preview Pattern: preview-{PORT}.$BASE_DOMAIN"
        echo "   Port Range: 8500-8999"
    fi
    echo ""
    echo "👉 SSL SETUP:"
    if [[ "$GLOBAL_PREVIEW_SETUP" == true ]] && [ -f "/etc/letsencrypt/live/$BASE_DOMAIN/fullchain.pem" ]; then
        echo "   ✅ Wildcard SSL certificate installed for $BASE_DOMAIN"
    else
        echo "   Run: sudo certbot --nginx -d $DOMAIN_NAME"
    fi
    echo "=================================================="
else
    echo ""
    echo "=================================================="
    echo "✅ Atomic Setup for '$APP_NAME' complete!"
    echo "=================================================="
    echo "   - Deploy Path: $APP_ROOT"
    echo "   - Releases: $APP_ROOT/releases"
    echo "   - Current Symlink: $APP_ROOT/current"
    echo "   - URL: http://$DOMAIN_NAME"
    echo "   - Port: $APP_PORT"
    echo "=================================================="
fi
