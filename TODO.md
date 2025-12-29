# TODO & Missing Features

This document tracks all missing features, incomplete implementations, and planned enhancements.

## 🚨 High Priority - Missing Features

### PR Preview Deployments

#### Monorepo Support
- [ ] **Version 1 Monorepo PR Preview**
  - [ ] Create `.github/workflows/preview-deploy-web.yml` for monorepo
  - [ ] Create `.github/workflows/preview-deploy-admin.yml` for monorepo
  - [ ] Update setup script to configure preview directories per app
  - [ ] Test PR preview with multiple apps in monorepo
  - [ ] Handle port conflicts between apps
  - [ ] Update documentation

- [ ] **Version 1.5 Monorepo PR Preview**
  - [ ] Create atomic preview deployment workflows for monorepo
  - [ ] Per-app preview release management
  - [ ] Preview cleanup per app
  - [ ] Test atomic preview deployments
  - [ ] Update documentation

#### Version 2 (Git Pull) PR Preview
- [ ] **PR Preview for Git Pull Strategy**
  - [ ] Create `.github/workflows/preview-deploy.yml` for Git Pull
  - [ ] Update setup script to support preview deployments
  - [ ] Configure Nginx for dynamic preview routing
  - [ ] Wildcard SSL certificate setup for Git Pull
  - [ ] Test PR preview with Git Pull strategy
  - [ ] Update documentation

### Staging Deployments

#### Monorepo Support
- [ ] **Version 1 Monorepo Staging**
  - [ ] Create `.github/workflows/staging-deploy-web.yml` for monorepo
  - [ ] Create `.github/workflows/staging-deploy-admin.yml` for monorepo
  - [ ] Per-app staging directory structure
  - [ ] Test staging deployments
  - [ ] Update documentation

- [ ] **Version 1.5 Monorepo Staging**
  - [ ] Create atomic staging deployment workflows for monorepo
  - [ ] Per-app staging release management
  - [ ] Test atomic staging deployments
  - [ ] Update documentation

#### Version 2 (Git Pull) Staging
- [ ] **Staging for Git Pull Strategy**
  - [ ] Create `.github/workflows/staging-deploy.yml` for Git Pull
  - [ ] Update setup script to support staging
  - [ ] Configure Nginx for staging routing
  - [ ] Test staging with Git Pull strategy
  - [ ] Update documentation

### Git Pull Monorepo Support

- [ ] **Complete Monorepo Implementation for Version 2**
  - [ ] Create `v2-do-git-pm2-monorepo/` directory
  - [ ] Create `setup_monorepo_git.sh` script
  - [ ] Support multiple apps on one server
  - [ ] Path-based filtering for Git Pull
  - [ ] Per-app Git repository handling
  - [ ] Create monorepo workflow examples
  - [ ] Create README for Git Pull monorepo
  - [ ] Test multi-app Git Pull deployments

- [ ] **Git Pull Monorepo Features**
  - [ ] PR preview for Git Pull monorepo
  - [ ] Staging for Git Pull monorepo
  - [ ] Wildcard SSL for Git Pull monorepo
  - [ ] Independent app deployments
  - [ ] Port isolation per app

## 📋 Medium Priority - Enhancements

### Workflow Improvements

- [ ] **Preview Deployment Cleanup**
  - [ ] Automatic cleanup of old PR previews
  - [ ] Configurable retention period
  - [ ] Cleanup on PR close/merge
  - [ ] PM2 process cleanup

- [ ] **Staging to Production Promotion**
  - [ ] One-click promotion workflow
  - [ ] Staging validation checks
  - [ ] Automated promotion on approval

- [ ] **Multi-Environment Management**
  - [ ] Environment-specific configurations
  - [ ] Environment variable management
  - [ ] Environment promotion workflows

### Documentation

- [ ] **Missing Documentation**
  - [ ] PR preview setup guide for monorepos
  - [ ] Staging setup guide for monorepos
  - [ ] Git Pull monorepo guide
  - [ ] Troubleshooting guides for each strategy
  - [ ] Video tutorials

## 🔄 Low Priority - Future Enhancements

### Advanced Features

- [ ] **Preview Deployment Enhancements**
  - [ ] Preview URL sharing
  - [ ] Preview deployment notifications
  - [ ] Preview health checks
  - [ ] Preview deployment metrics

- [ ] **Staging Enhancements**
  - [ ] Staging database seeding
  - [ ] Staging data management
  - [ ] Staging environment isolation

- [ ] **Git Pull Enhancements**
  - [ ] Branch-based deployments
  - [ ] Tag-based deployments
  - [ ] Selective file deployment

## ✅ Completed Features

- ✅ Version 1 single app PR preview
- ✅ Version 1 single app staging
- ✅ Version 1.5 single app PR preview
- ✅ Version 1.5 single app staging
- ✅ Version 1 monorepo basic deployment
- ✅ Version 1.5 monorepo basic deployment
- ✅ Wildcard SSL setup for Version 1 & 1.5
- ✅ Dynamic Nginx routing for previews

## 📝 Notes

### Why These Features Are Missing

1. **Monorepo Preview/Staging**: The setup scripts support it, but workflow files weren't created yet
2. **Git Pull Preview/Staging**: Requires Nginx configuration and workflow creation
3. **Git Pull Monorepo**: Complete implementation needed from scratch

### Implementation Order Recommendation

1. **First**: Monorepo PR preview for Version 1 (easiest, most requested)
2. **Second**: Monorepo staging for Version 1
3. **Third**: Git Pull PR preview and staging
4. **Fourth**: Git Pull monorepo support
5. **Fifth**: Version 1.5 monorepo preview/staging

### Contribution Opportunities

These missing features are great opportunities for contributions! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

