# ⚛️ Atomic Deployment Pipeline

This project uses an **Atomic Symlink Deployment** strategy.
This ensures zero downtime and instant rollbacks by never modifying the live folder directly.

## 📂 Folder Architecture (On Server)
```text
/home/deploy/app/
├── releases/                <-- Stores all upload versions
│   ├── 202512291000/        <-- Old Release
│   ├── 202512291100/        <-- Current Active Code
│   └── 202512291200/        <-- Incoming Upload
├── current -> releases/202512291100  <-- Symlink (Nginx points here)
└── scripts/
    └── atomic_switch.sh     <-- Script that flips the link
```

## 🛡️ Security & Reliability

- **Partial Failure Protection:** If the internet cuts out during rsync, the releases/new_folder is incomplete, but the current symlink still points to the old, working code. The site never breaks.

- **Rollback Capability:** If you deploy a bug, you don't need to rebuild. Just SSH in and point the symlink back to the previous timestamp folder.

## 🛠️ Setup

1. Run `setup_vps_atomic.sh` on your server.
2. Add the `SSH_PRIVATE_KEY` to GitHub Secrets.
3. Ensure `ecosystem.config.js` is in your project root.

## 🚨 How to Rollback Manually

If a bad deploy happens, run this on the server:

```bash
# 1. View available releases
ls -l ~/app/releases

# 2. Point 'current' to the previous timestamp
ln -sfn ~/app/releases/2025... ~/app/current

# 3. Reload PM2
cd ~/app/current
pm2 reload ecosystem.config.js
```