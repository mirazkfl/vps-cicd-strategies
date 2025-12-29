# 🏗️ Deployment Pipeline (Git Pull + Server Build)

This project uses a "Pull-based" workflow.
**Strategy:** GitHub Action triggers SSH → Server pulls code → Server builds app.

## 🛡️ Security
- **Deploy Keys:** Access to the repository is granted via a specific readonly SSH Deploy Key generated on the server.
- **Access Control:** The GitHub Action only has access to trigger the deploy script, not to view the server's file system directly.

## ⚡ Performance Note
- **Swap Space:** The setup script creates a 4GB Swap file. This is **mandatory** for building Next.js apps on servers with <4GB RAM, otherwise the build process will be killed by the OS.

## 🛠️ Setup
1. Run `setup_vps_git.sh` on your server.
2. **Crucial:** The script will output a public key (starts with `ssh-ed25519...`). 
   - Go to your GitHub Repo -> Settings -> **Deploy keys** -> Add Deploy key.
   - Paste that key there.
3. **Manual Step:** You must SSH into the server once manually to clone the repo for the first time:
   ```bash
   ssh deploy@your_ip
   git clone git@github.com:your/repo.git ~/project_repo
   ```
4. Create an `ecosystem.config.js` in your repo root (ensure script points to `npm start` or your server entry point).

## 🚀 How to Deploy

Push to main. The server will pull the changes, install npm packages, rebuild the app, and reload PM2.