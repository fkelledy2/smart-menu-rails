# Git Branching Strategy

This document outlines the git branching strategy for the Smart Menu Rails application, aligned with the Heroku multi-environment deployment setup.

## Branch Structure

```
main (production)
├── staging
└── development
```

## Branch Mapping

| Branch | Heroku App | Environment | Purpose |
|--------|-----------|-------------|---------|
| `main` | `smart-menus` | Production | Live production environment |
| `staging` | `smart-menus-staging` | Staging | Pre-production testing and QA |
| `development` | `smart-menus-dev` | Development | Active development and testing |

## Workflow

### Development Flow

1. **Feature Development**
   ```bash
   # Create feature branch from development
   git checkout development
   git pull origin development
   git checkout -b feature/your-feature-name
   
   # Work on your feature
   git add .
   git commit -m "Add feature description"
   
   # Push feature branch
   git push origin feature/your-feature-name
   ```

2. **Merge to Development**
   ```bash
   # Create PR: feature/your-feature-name → development
   # After PR approval and merge, deploy to dev
   git checkout development
   git pull origin development
   ./heroku/dev/deploy.sh
   ```

3. **Promote to Staging**
   ```bash
   # After testing in development, promote to staging
   git checkout staging
   git pull origin staging
   git merge development
   git push origin staging
   ./heroku/staging/deploy.sh
   ```

4. **Promote to Production**
   ```bash
   # After QA approval in staging, promote to production
   git checkout main
   git pull origin main
   git merge staging
   git push origin main
   ./heroku/production/deploy.sh
   ```

### Hotfix Flow

For critical production fixes:

```bash
# Create hotfix branch from main
git checkout main
git pull origin main
git checkout -b hotfix/critical-fix-name

# Make the fix
git add .
git commit -m "Fix critical issue"

# Merge to main (production)
git checkout main
git merge hotfix/critical-fix-name
git push origin main
./heroku/production/deploy.sh

# Backport to staging
git checkout staging
git merge hotfix/critical-fix-name
git push origin staging

# Backport to development
git checkout development
git merge hotfix/critical-fix-name
git push origin development

# Delete hotfix branch
git branch -d hotfix/critical-fix-name
git push origin --delete hotfix/critical-fix-name
```

## Branch Protection Rules

### Recommended GitHub Settings

#### `main` (Production)
- ✅ Require pull request reviews before merging (2 approvals)
- ✅ Require status checks to pass before merging
- ✅ Require branches to be up to date before merging
- ✅ Require conversation resolution before merging
- ✅ Do not allow bypassing the above settings
- ✅ Restrict who can push to matching branches (admins only)

#### `staging` (Staging)
- ✅ Require pull request reviews before merging (1 approval)
- ✅ Require status checks to pass before merging
- ✅ Require branches to be up to date before merging
- ✅ Allow admins to bypass

#### `development` (Development)
- ✅ Require status checks to pass before merging
- ✅ Allow direct pushes for rapid development
- ⚠️ Optional: Require PR reviews (can be relaxed for development)

## Deployment Strategy

### Automatic Deployments (Optional)

You can configure automatic deployments in Heroku:

```bash
# Development - auto-deploy from development branch
heroku git:remote -a smart-menus-dev
heroku labs:enable runtime-dyno-metadata -a smart-menus-dev

# Staging - auto-deploy from staging branch
heroku git:remote -a smart-menus-staging
heroku labs:enable runtime-dyno-metadata -a smart-menus-staging

# Production - manual deployment only (recommended)
# Use ./heroku/production/deploy.sh for controlled releases
```

### Manual Deployments (Recommended)

Use the environment-specific deployment scripts:

```bash
# Development
./heroku/dev/deploy.sh development

# Staging
./heroku/staging/deploy.sh staging

# Production
./heroku/production/deploy.sh main
```

## Best Practices

### 1. **Never commit directly to main**
Always use pull requests and code review for production changes.

### 2. **Test in development first**
All features should be tested in development before promoting to staging.

### 3. **QA in staging**
Staging should mirror production as closely as possible for final QA.

### 4. **Keep branches in sync**
Regularly merge changes from main → staging → development to keep branches aligned.

### 5. **Use semantic commit messages**
```
feat: Add new feature
fix: Fix bug in component
docs: Update documentation
refactor: Refactor code structure
test: Add or update tests
chore: Update dependencies
```

### 6. **Tag production releases**
```bash
git checkout main
git tag -a v1.2.3 -m "Release version 1.2.3"
git push origin v1.2.3
```

## Troubleshooting

### Branches Out of Sync

If branches diverge, you may need to rebase or merge:

```bash
# Option 1: Merge (preserves history)
git checkout staging
git merge main

# Option 2: Rebase (cleaner history, use with caution)
git checkout staging
git rebase main
```

### Deployment Conflicts

If you encounter conflicts during deployment:

```bash
# Resolve conflicts locally
git checkout staging
git merge development
# Fix conflicts
git add .
git commit -m "Resolve merge conflicts"
git push origin staging
./heroku/staging/deploy.sh
```

### Rollback a Deployment

```bash
# Heroku rollback
heroku releases -a smart-menus
heroku rollback v123 -a smart-menus

# Or git revert
git checkout main
git revert HEAD
git push origin main
./heroku/production/deploy.sh
```

## Quick Reference

### Common Commands

```bash
# Check current branch
git branch

# Switch branches
git checkout development
git checkout staging
git checkout main

# View branch history
git log --oneline --graph --all

# Compare branches
git diff development..staging
git diff staging..main

# Delete merged feature branch
git branch -d feature/branch-name
git push origin --delete feature/branch-name
```

### Deployment Commands

```bash
# Deploy to development
./heroku/dev/deploy.sh

# Deploy to staging
./heroku/staging/deploy.sh

# Deploy to production (with confirmation)
./heroku/production/deploy.sh

# View logs
./heroku/dev/tail.sh
./heroku/staging/tail.sh
./heroku/production/tail.sh
```

## CI/CD Integration

### GitHub Actions Workflow (Example)

```yaml
# .github/workflows/deploy.yml
name: Deploy

on:
  push:
    branches:
      - development
      - staging
      - main

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Deploy to Development
        if: github.ref == 'refs/heads/development'
        run: |
          # Deploy to smart-menus-dev
          
      - name: Deploy to Staging
        if: github.ref == 'refs/heads/staging'
        run: |
          # Deploy to smart-menus-staging
          
      - name: Deploy to Production
        if: github.ref == 'refs/heads/main'
        run: |
          # Deploy to smart-menus (with approval)
```

## Support

For questions or issues with the branching strategy:
1. Check this documentation
2. Review the Heroku deployment scripts in `/heroku/`
3. Consult the team lead or DevOps engineer
