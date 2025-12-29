# Contributing to CI/CD Deployment Strategies

First off, thank you for considering contributing to this project! 🎉

This document provides guidelines and instructions for contributing. Following these guidelines helps communicate that you respect the time of the developers managing and developing this open source project. In return, they should reciprocate that respect in addressing your issue, assessing changes, and helping you finalize your pull requests.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [How Can I Contribute?](#how-can-i-contribute)
- [Development Setup](#development-setup)
- [Contribution Process](#contribution-process)
- [Coding Standards](#coding-standards)
- [Testing Guidelines](#testing-guidelines)
- [Commit Message Guidelines](#commit-message-guidelines)
- [Pull Request Process](#pull-request-process)
- [Reporting Bugs](#reporting-bugs)
- [Suggesting Enhancements](#suggesting-enhancements)
- [Project Structure](#project-structure)
- [Areas for Contribution](#areas-for-contribution)
- [Questions?](#questions)

## 📜 Code of Conduct

This project adheres to a Code of Conduct that all contributors are expected to follow. Please read [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) before participating.

### Our Pledge

- Be respectful and inclusive
- Welcome newcomers and help them learn
- Focus on constructive feedback
- Respect different viewpoints and experiences

## 🤔 How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the issue list as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

- **Clear title and description**
- **Steps to reproduce** the issue
- **Expected behavior**
- **Actual behavior**
- **Environment details** (OS, Node version, server type, etc.)
- **Screenshots or logs** (if applicable)
- **Possible solution** (if you have ideas)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

- **Clear title and description**
- **Use case** - Why is this enhancement useful?
- **Proposed solution** - How should it work?
- **Alternatives considered** - What other approaches did you consider?
- **Additional context** - Any other relevant information

### Pull Requests

- Fill in the required template
- Do not include issue numbers in the PR title
- Include screenshots and animated GIFs in your pull request whenever possible
- Follow the [Coding Standards](#coding-standards)
- Include thoughtfully-worded, well-structured tests
- Document new code based on the [Documentation Styleguide](#documentation-styleguide)
- End all files with a newline

## 🛠️ Development Setup

### Prerequisites

- **Git** (latest version)
- **Bash** (for running setup scripts)
- **Node.js** 20+ (for testing Next.js builds)
- **Access to a VPS** (Ubuntu 20.04/22.04/24.04) for testing
- **SSH access** to test server
- **Basic knowledge** of:
  - Shell scripting
  - Nginx configuration
  - PM2 process management
  - GitHub Actions workflows

### Getting Started

1. **Fork the repository**
   ```bash
   # Click the "Fork" button on GitHub
   ```

2. **Clone your fork**
   ```bash
   git clone https://github.com/YOUR_USERNAME/cicd.git
   cd cicd
   ```

3. **Add upstream remote**
   ```bash
   git remote add upstream https://github.com/ORIGINAL_OWNER/cicd.git
   ```

4. **Create a branch**
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/your-bug-fix
   ```

5. **Make your changes**
   - Edit files
   - Test thoroughly
   - Update documentation

6. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

7. **Push to your fork**
   ```bash
   git push origin feature/your-feature-name
   ```

8. **Create a Pull Request**
   - Go to the original repository on GitHub
   - Click "New Pull Request"
   - Select your branch
   - Fill out the PR template

## 🔄 Contribution Process

### 1. Find an Issue or Create One

- Check existing [issues](https://github.com/ORIGINAL_OWNER/cicd/issues)
- Look for issues labeled `good first issue` or `help wanted`
- If you want to work on something new, create an issue first to discuss

### 2. Claim the Issue

- Comment on the issue to let others know you're working on it
- This prevents duplicate work

### 3. Create Your Branch

```bash
# Update your main branch
git checkout main
git pull upstream main

# Create feature branch
git checkout -b feature/issue-number-short-description
# Example: git checkout -b feature/123-add-docker-support
```

### 4. Make Changes

- Write clean, maintainable code
- Follow coding standards
- Add tests if applicable
- Update documentation

### 5. Test Your Changes

See [Testing Guidelines](#testing-guidelines) for detailed instructions.

### 6. Commit Your Changes

Follow [Commit Message Guidelines](#commit-message-guidelines).

### 7. Push and Create Pull Request

```bash
git push origin feature/your-branch-name
```

Then create a Pull Request on GitHub.

## 📝 Coding Standards

### Shell Script Standards

- **Use `#!/bin/bash`** shebang
- **Set `set -e`** to exit on error
- **Quote variables** to prevent word splitting
- **Use meaningful variable names**
- **Add comments** for complex logic
- **Check for directory existence** before operations
- **Handle errors gracefully** with proper error messages

**Good Example:**
```bash
#!/bin/bash
set -e

APP_ROOT="/home/$DEPLOY_USER/app"
if [ ! -d "$APP_ROOT" ]; then
    echo "📁 Creating app directory..."
    mkdir -p "$APP_ROOT"
    chown -R "$DEPLOY_USER:$DEPLOY_USER" "$APP_ROOT"
fi
```

**Bad Example:**
```bash
mkdir $APP_ROOT
chown $DEPLOY_USER $APP_ROOT
```

### YAML Standards (GitHub Actions)

- **Use consistent indentation** (2 spaces)
- **Quote strings** when they contain special characters
- **Use descriptive step names**
- **Group related steps** logically
- **Add comments** for complex workflows

**Good Example:**
```yaml
- name: Sync Files to Server (Rsync)
  run: |
    mkdir -p ~/.ssh
    ssh-keyscan -H ${{ secrets.DROPLET_IP }} >> ~/.ssh/known_hosts
    rsync -avz --delete ./deploy_package/ ${{ secrets.DROPLET_USER }}@${{ secrets.DROPLET_IP }}:/home/${{ secrets.DROPLET_USER }}/app/
```

### File Naming

- **Use lowercase** with hyphens: `setup-vps.sh`
- **Be descriptive**: `atomic-switch.sh` not `switch.sh`
- **Use consistent naming** across similar files

### Documentation Standards

- **Use clear, concise language**
- **Include code examples** where helpful
- **Add tables** for comparisons
- **Use emojis sparingly** for visual organization
- **Keep README files updated**

## 🧪 Testing Guidelines

### Testing Checklist

Before submitting a PR, ensure:

- [ ] **Fresh Server Test**
  - Test on clean Ubuntu 20.04/22.04/24.04
  - Verify all components install correctly
  - Test end-to-end deployment workflow

- [ ] **Directory Creation**
  - Verify all directories are created
  - Check permissions are correct
  - Ensure ownership is set properly

- [ ] **Nginx Configuration**
  - Run `nginx -t` to validate config
  - Test HTTP to HTTPS redirect
  - Verify proxy settings work

- [ ] **SSL Certificates**
  - Test certificate generation (if applicable)
  - Verify certificate renewal works
  - Check wildcard certificate setup

- [ ] **PM2 Processes**
  - Verify processes start correctly
  - Test zero-downtime reload
  - Check process names are unique
  - Verify cluster mode works

- [ ] **Deployment Workflow**
  - Test full deployment cycle
  - Verify artifacts are transferred correctly
  - Check PM2 reload works
  - Test rollback (for Version 1.5)

- [ ] **Edge Cases**
  - Test with missing directories
  - Test with existing configurations
  - Test with invalid inputs
  - Test failure scenarios

- [ ] **Security**
  - Verify SSH key permissions (600)
  - Check file ownership
  - Validate Nginx security headers
  - Test firewall rules

### Testing Environment Setup

1. **Create a test VPS**
   ```bash
   # Use DigitalOcean, AWS, or any VPS provider
   # Ubuntu 20.04/22.04/24.04 recommended
   ```

2. **SSH into server**
   ```bash
   ssh root@your-test-server-ip
   ```

3. **Run setup script**
   ```bash
   # Copy your modified script
   nano setup_vps.sh
   # Paste your changes
   bash setup_vps.sh
   ```

4. **Test deployment**
   ```bash
   # Trigger GitHub Actions workflow
   # Or manually test rsync/git pull
   ```

5. **Verify everything works**
   ```bash
   # Check PM2 processes
   pm2 list
   
   # Check Nginx
   nginx -t
   systemctl status nginx
   
   # Test deployment
   curl http://your-domain.com
   ```

### Automated Testing (Future)

We plan to add:
- [ ] Automated script validation
- [ ] Integration tests
- [ ] End-to-end deployment tests
- [ ] Security scanning

## 📝 Commit Message Guidelines

We follow [Conventional Commits](https://www.conventionalcommits.org/) specification.

### Format

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

### Scope

Optional, but recommended:
- `setup`: Setup scripts
- `workflow`: GitHub Actions workflows
- `nginx`: Nginx configuration
- `docs`: Documentation
- `monorepo`: Monorepo-specific changes

### Examples

**Good:**
```
feat(setup): add PR preview deployment support

- Add prompts for PR preview configuration
- Configure wildcard SSL certificates
- Set up dynamic Nginx port mapping

Closes #123
```

```
fix(workflow): ensure PORT is passed to PM2 correctly

The PORT environment variable wasn't being passed correctly
to PM2 processes in preview deployments. This fix ensures
PORT is available to the Node.js process.

Fixes #456
```

**Bad:**
```
update files
```

```
fix bug
```

```
WIP: trying something
```

### Body

- Use imperative mood: "add" not "added" or "adds"
- Explain **what** and **why** vs. **how**
- Reference issues and PRs

### Footer

- Reference issues: `Closes #123`
- Breaking changes: `BREAKING CHANGE: description`

## 🔀 Pull Request Process

### Before Submitting

1. **Update your branch**
   ```bash
   git checkout main
   git pull upstream main
   git checkout your-branch
   git rebase upstream/main
   ```

2. **Run tests**
   - Follow [Testing Guidelines](#testing-guidelines)
   - Ensure all checks pass

3. **Update documentation**
   - Update relevant README files
   - Add code comments
   - Update this CONTRIBUTING.md if needed

### PR Template

When creating a PR, fill out:

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Breaking change
- [ ] Documentation update

## Testing
- [ ] Fresh server test completed
- [ ] Nginx configuration validated
- [ ] PM2 processes verified
- [ ] Deployment workflow tested
- [ ] Edge cases tested

## Checklist
- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No new warnings generated
- [ ] Tests added/updated
- [ ] All tests pass

## Related Issues
Closes #123
```

### Review Process

1. **Automated checks** run first
2. **Maintainers review** your code
3. **Address feedback** if requested
4. **Make changes** and push updates
5. **Approval** from maintainer
6. **Merge** by maintainer

### After Approval

- Maintainers will merge your PR
- Your changes will be included in the next release
- Thank you for contributing! 🎉

## 🐛 Reporting Bugs

### Before Submitting

1. **Check existing issues** - Your bug might already be reported
2. **Test on latest version** - Bug might be fixed already
3. **Gather information** - Collect logs, error messages, etc.

### Bug Report Template

```markdown
**Describe the bug**
A clear and concise description of what the bug is.

**To Reproduce**
Steps to reproduce the behavior:
1. Run '...'
2. Configure '...'
3. Deploy '...'
4. See error

**Expected behavior**
A clear and concise description of what you expected to happen.

**Actual behavior**
What actually happened.

**Environment:**
- OS: [e.g., Ubuntu 22.04]
- Node version: [e.g., 20.10.0]
- Server type: [e.g., DigitalOcean Droplet]
- Strategy version: [e.g., v1, v1.5, v2]
- Monorepo: [Yes/No]

**Screenshots/Logs**
If applicable, add screenshots or logs to help explain your problem.

**Additional context**
Add any other context about the problem here.
```

## 💡 Suggesting Enhancements

### Enhancement Request Template

```markdown
**Is your enhancement request related to a problem?**
A clear and concise description of what the problem is.

**Describe the solution you'd like**
A clear and concise description of what you want to happen.

**Describe alternatives you've considered**
A clear and concise description of any alternative solutions or features.

**Use case**
Why is this enhancement useful? Who would benefit?

**Additional context**
Add any other context, mockups, or examples about the enhancement.
```

## 📁 Project Structure

```
cicd/
├── v1-do-rsync-pm2/              # Version 1: Rsync + PM2
│   ├── setup_vps.sh
│   ├── ecosystem.config.js
│   ├── README.md
│   └── .github/workflows/
├── v1.5-do-rsync-atomic-pm2/    # Version 1.5: Atomic Deployment
│   ├── setup_vps_atomic.sh
│   ├── atomic_switch.sh
│   ├── ecosystem.config.js
│   ├── README.md
│   └── .github/workflows/
├── v2-do-git-pm2/                # Version 2: Git Pull
│   ├── setup_vps_git.sh
│   ├── ecosystem.config.js
│   ├── README.md
│   └── .github/workflows/
├── v1-do-rsync-pm2-monorepo/     # Monorepo Version 1
├── v1.5-do-rsync-atomic-pm2-monorepo/  # Monorepo Version 1.5
├── README.md                      # Main documentation
├── CONTRIBUTING.md               # This file
└── CODE_OF_CONDUCT.md            # Code of conduct
```

### Where to Make Changes

- **Setup scripts**: `*/setup*.sh`
- **Workflows**: `*/.github/workflows/*.yml`
- **Documentation**: `*/README.md` or root `README.md`
- **Config examples**: `*/ecosystem.config.js`

## 🎯 Areas for Contribution

We especially welcome contributions in:

### High Priority

- 🐳 **Docker Support**
  - Dockerfile templates
  - Docker Compose setups
  - Container deployment workflows

- ☸️ **Kubernetes**
  - Kubernetes manifests
  - Helm charts
  - Deployment strategies

- 📊 **Monitoring**
  - Prometheus integration
  - Grafana dashboards
  - Log aggregation

### Medium Priority

- 🔒 **Security**
  - Security scanning
  - Secrets management
  - WAF integration

- ⚡ **Performance**
  - CDN integration
  - Caching strategies
  - Database optimization

- 🧪 **Testing**
  - Automated tests
  - Integration tests
  - E2E tests

### Always Welcome

- 📝 **Documentation**
  - Tutorials
  - Examples
  - Troubleshooting guides

- 🐛 **Bug Fixes**
  - Any bugs you find
  - Edge cases
  - Error handling

- 💡 **Enhancements**
  - New features
  - Improvements
  - Optimizations

## ❓ Questions?

- **GitHub Discussions**: For questions and general discussion
- **GitHub Issues**: For bug reports and feature requests
- **Pull Requests**: For code contributions

Don't hesitate to ask questions! We're here to help.

## 🙏 Recognition

Contributors will be:
- Listed in the project README
- Credited in release notes
- Appreciated by the community!

Thank you for contributing to this project! 🎉

