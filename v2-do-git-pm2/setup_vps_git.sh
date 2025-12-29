#!/bin/bash

# ---
# VPS Setup Script (Version 2: Git Pull + Server Build)
# ---

set -e

echo "=================================================="
echo "   🚀 Server Setup (Git Pull Strategy)"
echo "=================================================="

# 1. Inputs
read -p "🔹 Enter deploy username (e.g., deploy): " DEPLOY_USER
read -p "🔹 Enter domain name (e.g., example.com): " DOMAIN_NAME
read -p "🔹 Enter Git Repo URL (SSH format: git@github.com:user/repo.git): " REPO_URL
read -p "🔹 Enter Node.js version (default 20): " NODE_VERSION
NODE_VERSION=${NODE_VERSION:-20}

# 2. Add Swap Space (Crucial for server-side builds)
echo "💾 Checking Swap Space..."
if [ $(swapon --show | wc -l) -eq 0 ]; then
    echo "   Creating 4GB Swap file to prevent build crashes..."
    fallocate -l 4G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
    echo "✅ Swap created."
else
    echo "✅ Swap already exists."
fi

# 3. System Updates
apt update && apt upgrade -y
apt install -y curl git ufw nginx certbot python3-certbot-nginx

# 4. Firewall
ufw allow OpenSSH
ufw allow 'Nginx Full'
ufw --force enable

# 5. User Setup
if ! id "$DEPLOY_USER" &>/dev/null; then
    useradd -m -s /bin/bash "$DEPLOY_USER"
    usermod -aG sudo "$DEPLOY_USER"
    echo "⚠️ Set password for $DEPLOY_USER:"
    passwd "$DEPLOY_USER"
fi

# 6. SSH Setup
USER_HOME="/home/$DEPLOY_USER"
mkdir -p "$USER_HOME/.ssh"
if [ -f /root/.ssh/authorized_keys ]; then
    cp /root/.ssh/authorized_keys "$USER_HOME/.ssh/authorized_keys"
fi

# Generate TWO keys:
# 1. Action Key: For GitHub Actions to login to THIS server
# 2. Deploy Key: For THIS server to pull from GitHub
ACTION_KEY="$USER_HOME/.ssh/github_action_key"
DEPLOY_KEY="$USER_HOME/.ssh/id_ed25519"

if [ ! -f "$ACTION_KEY" ]; then
    ssh-keygen -t ed25519 -f "$ACTION_KEY" -N "" -C "github-action-access"
    cat "$ACTION_KEY.pub" >> "$USER_HOME/.ssh/authorized_keys"
fi

if [ ! -f "$DEPLOY_KEY" ]; then
    ssh-keygen -t ed25519 -f "$DEPLOY_KEY" -N "" -C "server-deploy-key"
fi

# Permissions
chown -R "$DEPLOY_USER:$DEPLOY_USER" "$USER_HOME/.ssh"
chmod 700 "$USER_HOME/.ssh"
chmod 600 "$USER_HOME/.ssh/authorized_keys" "$ACTION_KEY" "$DEPLOY_KEY"

# 7. Add GitHub to known_hosts to prevent interactive prompt hang
sudo -u "$DEPLOY_USER" ssh-keyscan github.com >> "$USER_HOME/.ssh/known_hosts"

# 8. Install Node & PM2
sudo -u "$DEPLOY_USER" bash <<EOF
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"
nvm install $NODE_VERSION
nvm use $NODE_VERSION
npm install -g pm2
EOF

# 9. Clone Repo (First Run)
echo "📥 Cloning Repository..."
# We can't clone yet because the user hasn't added the key to GitHub.
# We will create the folder and instruct the user.
mkdir -p "$USER_HOME/project_repo"
chown "$DEPLOY_USER:$DEPLOY_USER" "$USER_HOME/project_repo"

# 10. Nginx
cat > "/etc/nginx/sites-available/$DOMAIN_NAME" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN_NAME www.$DOMAIN_NAME;
    location / {
        proxy_pass http://127.0.0.1:3000; # Adjust port if needed
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF
ln -sf "/etc/nginx/sites-available/$DOMAIN_NAME" /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
systemctl restart nginx

# 11. Final Instructions
ACTION_PRIV_KEY=$(cat "$ACTION_KEY")
DEPLOY_PUB_KEY=$(cat "$DEPLOY_KEY.pub")

echo ""
echo "=================================================="
echo "✅ SETUP PART 1 COMPLETE"
echo "=================================================="
echo "👉 STEP 1: Add this 'Deploy Key' to your GitHub Repo (Settings > Deploy keys):"
echo "   (Allow write access if you want the server to push tags/changes)"
echo "--------------------------------------------------"
echo "$DEPLOY_PUB_KEY"
echo "--------------------------------------------------"
echo ""
echo "👉 STEP 2: Add this 'Action Secret' to GitHub (Settings > Secrets > Actions):"
echo "   Name: SSH_PRIVATE_KEY"
echo "--------------------------------------------------"
echo "$ACTION_PRIV_KEY"
echo "--------------------------------------------------"
echo ""
echo "👉 STEP 3: Manual First Clone"
echo "   Log in as $DEPLOY_USER and run:"
echo "   git clone $REPO_URL ~/project_repo"
echo "=================================================="
