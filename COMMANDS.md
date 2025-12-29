# CI/CD Deployment Commands Reference

A comprehensive reference guide for managing deployments, monitoring, and troubleshooting in the CI/CD pipeline.

## Table of Contents

- [PM2 Process Management](#pm2-process-management)
- [Nginx Configuration](#nginx-configuration)
- [SSL/Certbot Management](#sslcertbot-management)
- [System Monitoring](#system-monitoring)
- [Port Management](#port-management)
- [Deployment Commands](#deployment-commands)
- [SSH & Remote Access](#ssh--remote-access)
- [Node.js & NPM](#nodejs--npm)
- [System Cleanup](#system-cleanup)
- [Git & GitHub Actions](#git--github-actions)
- [File Management](#file-management)

---

## PM2 Process Management

### Starting Applications

```bash
# Start app with specific name and port
pm2 start npm --name "app-name" -- start -- --port 3001

# Start with ecosystem config
pm2 start ecosystem.config.js

# Start with environment variables
pm2 start npm --name "app-name" -- start -- --port 3001 --update-env

# Start in cluster mode (multiple instances)
pm2 start ecosystem.config.js -i max
```

### Managing Processes

```bash
# List all processes
pm2 list

# Show detailed info about a process
pm2 show "app-name"

# Restart a process
pm2 restart "app-name"

# Restart with updated environment variables
pm2 restart "app-name" --update-env

# Stop a process
pm2 stop "app-name"

# Delete a process
pm2 delete "app-name"

# Delete all processes
pm2 delete all

# Reload (zero-downtime restart)
pm2 reload "app-name"
```

### Monitoring & Logs

```bash
# View logs
pm2 logs

# View logs for specific app
pm2 logs "app-name"

# View logs with timestamps
pm2 logs --timestamp

# Monitor processes (real-time)
pm2 monit

# Show process info
pm2 info "app-name"

# Save current process list
pm2 save

# Resurrect saved processes
pm2 resurrect

# Generate startup script
pm2 startup

# View process metrics
pm2 status
```

### PM2 Ecosystem Config

```bash
# Start with ecosystem file
pm2 start ecosystem.config.js

# Start specific app from ecosystem
pm2 start ecosystem.config.js --only "app-name"

# Reload ecosystem config
pm2 reload ecosystem.config.js
```

---

## Nginx Configuration

### Basic Operations

```bash
# Restart nginx
sudo systemctl restart nginx

# Reload nginx (no downtime)
sudo systemctl reload nginx

# Start nginx
sudo systemctl start nginx

# Stop nginx
sudo systemctl stop nginx

# Check nginx status
sudo systemctl status nginx

# Test nginx configuration
sudo nginx -t

# Test and reload nginx
sudo nginx -t && sudo service nginx reload
```

### Configuration Management

```bash
# Enable site (create symlink)
sudo ln -s /etc/nginx/sites-available/example.com /etc/nginx/sites-enabled/example.com

# Disable site (remove symlink)
sudo rm /etc/nginx/sites-enabled/example.com

# Edit nginx config
sudo nano /etc/nginx/sites-available/example.com

# View nginx config
sudo cat /etc/nginx/sites-available/example.com
```

### Logs

```bash
# View nginx error logs
sudo tail -f /var/log/nginx/error.log

# View nginx access logs
sudo tail -f /var/log/nginx/access.log

# View specific site logs
sudo tail -f /var/log/nginx/example.com.error.log
sudo tail -f /var/log/nginx/example.com.access.log

# Search error logs
sudo grep -i error /var/log/nginx/error.log
```

### Nginx Configuration for Preview Deployments

```bash
# Test nginx config after changes
sudo nginx -t

# Reload nginx to apply changes
sudo systemctl reload nginx

# View current nginx config
sudo cat /etc/nginx/sites-available/example.com
```

---

## SSL/Certbot Management

### Basic SSL Setup

```bash
# Setup certbot for nginx
sudo certbot --nginx

# Setup certbot for specific domain
sudo certbot --nginx -d example.com -d www.example.com

# Add domain to existing certificate
sudo certbot --nginx -d www.example.com -d www.example.com
```

### Wildcard SSL Certificates

#### DigitalOcean DNS

```bash
# Install DigitalOcean DNS plugin
sudo apt update
sudo apt install python3-certbot-dns-digitalocean

# Create credentials file
mkdir -p ~/.secrets/certbot
nano ~/.secrets/certbot/digitalocean.ini
# Add: dns_digitalocean_token = YOUR_TOKEN
chmod 600 ~/.secrets/certbot/digitalocean.ini

# Obtain wildcard certificate
sudo certbot certonly \
    --dns-digitalocean \
    --dns-digitalocean-credentials ~/.secrets/certbot/digitalocean.ini \
    -d example.com -d '*.example.com'
```

#### Cloudflare DNS

```bash
# Install Cloudflare DNS plugin
sudo apt update
sudo apt install python3-certbot-dns-cloudflare

# Create credentials file
mkdir -p ~/.secrets/certbot
nano ~/.secrets/certbot/cloudflare.ini
# Add: dns_cloudflare_api_token = YOUR_TOKEN
chmod 600 ~/.secrets/certbot/cloudflare.ini

# Obtain wildcard certificate
sudo certbot certonly \
    --dns-cloudflare \
    --dns-cloudflare-credentials ~/.secrets/certbot/cloudflare.ini \
    -d example.com -d '*.example.com'
```

### Certificate Renewal

```bash
# Test certificate renewal (dry run)
sudo certbot renew --dry-run

# Renew certificates manually
sudo certbot renew

# Renew specific certificate
sudo certbot renew --cert-name example.com

# Check certificate expiration
sudo certbot certificates
```

### Certificate Management

```bash
# List all certificates
sudo certbot certificates

# Revoke certificate
sudo certbot revoke --cert-path /etc/letsencrypt/live/example.com/cert.pem

# Delete certificate
sudo certbot delete --cert-name example.com
```

---

## System Monitoring

### CPU & Memory Monitoring

```bash
# Monitor CPU usage
top

# Monitor CPU usage (better interface)
htop

# Monitor memory usage (every 5 seconds)
watch -n 5 free -m

# Show memory usage
free -h

# Show disk usage
df -h

# Show disk usage for specific directory
du -sh /path/to/directory

# Show detailed disk usage
du -h --max-depth=1 /path/to/directory
```

### Process Monitoring

```bash
# Show running processes
ps aux

# Show processes for specific user
ps aux | grep username

# Show process tree
pstree

# Show process by name
pgrep -a process-name
```

### Network Monitoring

```bash
# Monitor network connections
netstat -tulpn

# Monitor network traffic
iftop

# Show network statistics
ss -tulpn

# Monitor network I/O
nethogs
```

---

## Port Management

### Check Port Usage

```bash
# Check if port is in use
lsof -i :8000

# Check port (better method)
sudo ss -tlnp | grep :8000

# Check all listening ports
sudo ss -tlnp

# Check port with netstat
sudo netstat -tlnp | grep :8000

# Find process using port
sudo lsof -i :8000
```

### Kill Process on Port

```bash
# Find and kill process on port
sudo kill -9 $(sudo lsof -t -i:8000)

# Alternative method
sudo fuser -k 8000/tcp
```

---

## Deployment Commands

### Rsync Deployment

```bash
# Basic rsync deployment
rsync -av --delete --partial source/ user@host:/destination/

# Rsync with bandwidth limit
rsync -av --delete --partial --bwlimit=5000 source/ user@host:/destination/

# Rsync with SSH key
rsync -av -e "ssh -i /path/to/key" source/ user@host:/destination/

# Rsync excluding files
rsync -av --exclude 'node_modules' --exclude '.git' source/ user@host:/destination/

# Dry run (test without copying)
rsync -av --dry-run source/ user@host:/destination/
```

### Build & Deploy

```bash
# Install dependencies
npm install

# Build project
npm run build

# Build for CI
npm run build:ci

# Clean build artifacts
npm run clean

# Start production server
npm start

# Start CI server
npm run start:ci
```

### Deployment Paths

```bash
# Staging deployment path
/home/deploy/foxhub/builds/preview/staging

# Preview deployment path (PR-based)
/home/deploy/foxhub/builds/preview/{PR_NUMBER}

# Production deployment path
/home/deploy/foxhub/builds/production
```

---

## SSH & Remote Access

### SSH Connection

```bash
# Basic SSH connection
ssh user@host

# SSH with key file
ssh -i /path/to/key user@host

# SSH without host key checking (for CI/CD)
ssh -o StrictHostKeyChecking=no user@host

# SSH with port
ssh -p 2222 user@host

# SSH and execute command
ssh user@host "command"
```

### SSH Key Management

```bash
# Generate SSH key
ssh-keygen -t ed25519 -f ~/.ssh/key_name -N "" -C "description"

# Copy SSH key to server
ssh-copy-id -i ~/.ssh/key.pub user@host

# Test SSH connection
ssh -T git@github.com
```

### Remote Commands

```bash
# Execute command remotely
ssh user@host "cd /path/to/app && pm2 restart app-name"

# Execute multiple commands
ssh user@host << 'ENDSSH'
  cd /path/to/app
  pm2 restart app-name
  pm2 logs app-name --lines 50
ENDSSH
```

---

## Node.js & NPM

### NVM (Node Version Manager)

```bash
# Source nvm
source ~/.nvm/nvm.sh

# Use specific Node version
nvm use 23

# Install Node version
nvm install 23

# Set default Node version
nvm alias default 23

# List installed versions
nvm list

# List available versions
nvm list-remote
```

### NPM Commands

```bash
# Install dependencies
npm install

# Install production dependencies only
npm install --production

# Update dependencies
npm update

# Run script
npm run script-name

# Check outdated packages
npm outdated

# Audit packages
npm audit

# Fix vulnerabilities
npm audit fix
```

---

## System Cleanup

### Package Cleanup

```bash
# Remove unused packages
sudo apt autoremove && sudo apt clean

# Remove unused packages and clean cache
sudo apt autoremove && sudo apt autoclean && sudo apt clean
```

### Cache Management

```bash
# Clear system cache
sudo sysctl -w vm.drop_caches=3 && sudo sync && echo 3 | sudo tee /proc/sys/vm/drop_caches

# Clear cache with monitoring (before and after)
free -h && sudo sysctl -w vm.drop_caches=3 && sudo sync && echo 3 | sudo tee /proc/sys/vm/drop_caches && free -h

# Clear npm cache
npm cache clean --force

# Clear PM2 logs
pm2 flush
```

### Disk Cleanup

```bash
# Find large files
find / -type f -size +100M 2>/dev/null

# Find large directories
du -h --max-depth=1 / | sort -hr | head -20

# Remove old logs
sudo journalctl --vacuum-time=7d

# Clean old kernels
sudo apt autoremove --purge
```

---

## Git & GitHub Actions

### Git Commands

```bash
# Clone repository
git clone repo-url

# Pull latest changes
git pull

# Check status
git status

# View logs
git log --oneline

# View recent commits
git log -10 --oneline

# Checkout branch
git checkout branch-name

# Create and checkout branch
git checkout -b branch-name
```

### GitHub Actions

```bash
# View workflow runs
gh run list

# View specific workflow run
gh run view RUN_ID

# View workflow logs
gh run view RUN_ID --log

# Rerun failed workflow
gh run rerun RUN_ID

# Cancel workflow
gh run cancel RUN_ID
```

### GitHub Secrets Management

```bash
# List secrets (requires gh CLI)
gh secret list

# Set secret
gh secret set SECRET_NAME --body "secret-value"

# Delete secret
gh secret delete SECRET_NAME
```

---

## File Management

### File Operations

```bash
# Create directory
mkdir -p /path/to/directory

# Copy files recursively
cp -r source/ destination/

# Move files
mv source destination

# Remove files
rm -f filename

# Remove directory recursively
rm -rf directory/

# Change ownership
chown -R user:group /path/to/directory

# Change permissions
chmod -R 755 /path/to/directory
```

### File Search

```bash
# Find files by name
find /path -name "filename"

# Find files by extension
find /path -name "*.js"

# Search in files
grep -r "search-term" /path

# Search with context
grep -r -C 3 "search-term" /path
```

### File Viewing

```bash
# View file
cat filename

# View file with line numbers
cat -n filename

# View file page by page
less filename

# View first lines
head -n 20 filename

# View last lines
tail -n 20 filename

# Follow file (live updates)
tail -f filename
```

---

## Troubleshooting Commands

### Check Service Status

```bash
# Check PM2 status
pm2 status

# Check Nginx status
sudo systemctl status nginx

# Check Node.js version
node --version

# Check npm version
npm --version

# Check disk space
df -h

# Check memory
free -h
```

### Debug Deployment Issues

```bash
# Check PM2 logs for errors
pm2 logs --err

# Check Nginx error logs
sudo tail -50 /var/log/nginx/error.log

# Check system logs
sudo journalctl -xe

# Check recent system logs
sudo journalctl -n 100

# Check failed services
sudo systemctl --failed
```

### Verify Deployment

```bash
# Check if app is running
pm2 show "app-name"

# Check if port is listening
sudo ss -tlnp | grep :PORT

# Test HTTP endpoint
curl http://localhost:PORT

# Test HTTPS endpoint
curl https://example.com

# Check SSL certificate
openssl s_client -connect example.com:443
```

---

## Quick Reference

### Most Used Commands

```bash
# Restart PM2 app
pm2 restart "app-name" --update-env

# Check PM2 status
pm2 list

# View PM2 logs
pm2 logs "app-name"

# Reload Nginx
sudo nginx -t && sudo systemctl reload nginx

# Check port
sudo ss -tlnp | grep :PORT

# Monitor resources
htop

# Check disk space
df -h

# View recent logs
pm2 logs --lines 100
```

---

## Notes

- Replace `app-name` with your actual PM2 process name
- Replace `example.com` with your actual domain
- Replace `PORT` with your actual port number
- Replace `user@host` with your actual SSH credentials
- Always test Nginx configuration before reloading: `sudo nginx -t`
- Use `--dry-run` flags when testing rsync or certbot operations
- Monitor logs regularly to catch issues early

---

**Last Updated:** See file modification date

