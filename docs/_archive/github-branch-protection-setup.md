# GitHub Branch Protection Setup Guide

This guide provides step-by-step instructions for setting up branch protection rules for the Smart Menu Rails repository.

## Quick Access

**Repository Settings URL:**
```
https://github.com/fkelledy2/smart-menu-rails/settings/branches
```

## Branch Protection Rules

### 1. Protection for `main` (Production)

**Navigate to:** Settings → Branches → Add branch protection rule

**Branch name pattern:** `main`

#### Required Settings:

**Protect matching branches:**
- ✅ **Require a pull request before merging**
  - ✅ Require approvals: **2**
  - ✅ Dismiss stale pull request approvals when new commits are pushed
  - ✅ Require review from Code Owners (if CODEOWNERS file exists)
  - ✅ Require approval of the most recent reviewable push

- ✅ **Require status checks to pass before merging**
  - ✅ Require branches to be up to date before merging
  - Select required status checks:
    - `ci` (if GitHub Actions CI workflow exists)
    - `tests` (if test workflow exists)
    - Any other critical checks

- ✅ **Require conversation resolution before merging**
  - Ensures all PR comments are resolved

- ✅ **Require signed commits** (optional but recommended)
  - Ensures commits are cryptographically signed

- ✅ **Require linear history** (optional)
  - Prevents merge commits, requires rebase or squash

- ✅ **Require deployments to succeed before merging** (optional)
  - Can require successful deployment to staging first

**Additional Settings:**
- ✅ **Do not allow bypassing the above settings**
  - Applies rules to administrators too
  
- ✅ **Restrict who can push to matching branches**
  - Specify: Repository administrators only
  - Or: Specific teams/users with deploy permissions

- ✅ **Allow force pushes: Everyone** → **Disable**
  - Prevents force pushes to main

- ✅ **Allow deletions** → **Disable**
  - Prevents accidental branch deletion

**Lock branch:**
- ⚠️ **Do not lock** - Keep unlocked for deployments

---

### 2. Protection for `staging` (Staging)

**Navigate to:** Settings → Branches → Add branch protection rule

**Branch name pattern:** `staging`

#### Required Settings:

**Protect matching branches:**
- ✅ **Require a pull request before merging**
  - ✅ Require approvals: **1**
  - ✅ Dismiss stale pull request approvals when new commits are pushed
  - ⚠️ Require review from Code Owners: Optional

- ✅ **Require status checks to pass before merging**
  - ✅ Require branches to be up to date before merging
  - Select required status checks:
    - `ci` (if GitHub Actions CI workflow exists)
    - `tests` (if test workflow exists)

- ✅ **Require conversation resolution before merging**

- ⚠️ **Require signed commits** (optional)

**Additional Settings:**
- ⚠️ **Allow specified actors to bypass required pull requests**
  - Add: Repository administrators
  - Allows admins to push directly for urgent fixes

- ✅ **Restrict who can push to matching branches**
  - Specify: Developers and administrators

- ✅ **Allow force pushes: Everyone** → **Disable**

- ✅ **Allow deletions** → **Disable**

---

### 3. Protection for `development` (Development)

**Navigate to:** Settings → Branches → Add branch protection rule

**Branch name pattern:** `development`

#### Recommended Settings:

**Protect matching branches:**
- ✅ **Require status checks to pass before merging**
  - ✅ Require branches to be up to date before merging
  - Select required status checks:
    - `ci` (if GitHub Actions CI workflow exists)
    - `tests` (if test workflow exists)

- ⚠️ **Require a pull request before merging** (optional)
  - If enabled: Require approvals: **1**
  - Can be disabled for rapid development

**Additional Settings:**
- ✅ **Allow specified actors to bypass required pull requests**
  - Add: All developers
  - Allows direct pushes for rapid iteration

- ⚠️ **Restrict who can push to matching branches** (optional)
  - Can be left open for all team members

- ✅ **Allow force pushes: Specify who can force push**
  - Add: Developers (for rebasing feature branches)

- ✅ **Allow deletions** → **Disable**

---

## Step-by-Step Setup Instructions

### For `main` Branch:

1. Go to https://github.com/fkelledy2/smart-menu-rails/settings/branches
2. Click **"Add branch protection rule"**
3. Enter branch name pattern: `main`
4. Configure settings as specified above
5. Click **"Create"** or **"Save changes"**

### For `staging` Branch:

1. Click **"Add branch protection rule"** again
2. Enter branch name pattern: `staging`
3. Configure settings as specified above
4. Click **"Create"** or **"Save changes"**

### For `development` Branch:

1. Click **"Add branch protection rule"** again
2. Enter branch name pattern: `development`
3. Configure settings as specified above
4. Click **"Create"** or **"Save changes"**

---

## Verification

After setting up the rules, verify they're working:

### Test `main` Protection:
```bash
# This should be blocked
git checkout main
echo "test" >> test.txt
git add test.txt
git commit -m "Test commit"
git push origin main
# Expected: Push rejected - requires PR
```

### Test `staging` Protection:
```bash
# This should be blocked
git checkout staging
echo "test" >> test.txt
git add test.txt
git commit -m "Test commit"
git push origin staging
# Expected: Push rejected - requires PR
```

### Test `development` Protection:
```bash
# This may be allowed depending on your settings
git checkout development
echo "test" >> test.txt
git add test.txt
git commit -m "Test commit"
git push origin development
# Expected: May succeed if direct pushes allowed
```

---

## GitHub Actions Integration

To make status checks work, ensure your `.github/workflows/` files include:

```yaml
name: CI

on:
  pull_request:
    branches:
      - main
      - staging
      - development
  push:
    branches:
      - main
      - staging
      - development

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run tests
        run: |
          bundle install
          bundle exec rails test
```

---

## CODEOWNERS File (Optional)

Create `.github/CODEOWNERS` to automatically request reviews:

```
# Global owners
* @fkelledy2

# Specific paths
/app/models/ @fkelledy2
/app/controllers/ @fkelledy2
/config/ @fkelledy2
/db/ @fkelledy2

# Heroku deployment scripts
/heroku/ @fkelledy2

# Critical files
/Gemfile @fkelledy2
/Gemfile.lock @fkelledy2
/package.json @fkelledy2
```

---

## Troubleshooting

### "Cannot push to protected branch"
- **Solution**: Create a pull request instead of pushing directly
- Use feature branches: `git checkout -b feature/my-feature`

### "Status checks have not completed"
- **Solution**: Wait for CI/CD workflows to complete
- Check GitHub Actions tab for workflow status

### "Requires 2 approvals but you're the only developer"
- **Solution**: Temporarily adjust approval count to 1
- Or add a second GitHub account as collaborator

### "Need to bypass protection for urgent hotfix"
- **Solution**: Use the hotfix workflow from git-branching-strategy.md
- Or temporarily disable protection (not recommended)

---

## Summary

| Branch | Approvals | Status Checks | Force Push | Direct Push |
|--------|-----------|---------------|------------|-------------|
| `main` | 2 required | Required | ❌ Disabled | ❌ Disabled |
| `staging` | 1 required | Required | ❌ Disabled | ⚠️ Admins only |
| `development` | Optional | Required | ⚠️ Developers | ✅ Allowed |

---

## Additional Resources

- [GitHub Branch Protection Documentation](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [GitHub CODEOWNERS Documentation](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)
- [Git Branching Strategy](/docs/git-branching-strategy.md)
