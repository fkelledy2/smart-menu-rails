# CI/CD Setup Guide

This document explains the CI/CD pipeline and quality assurance tools implemented for the Smart Menu Rails application.

## 🛠️ Tools Implemented

### 1. **RuboCop** - Code Style and Quality
- **Purpose**: Enforces Ruby style guide and catches common issues
- **Configuration**: `.rubocop.yml`
- **Extensions**: Rails, RSpec, Performance cops
- **Usage**: `bundle exec rubocop`

### 2. **Brakeman** - Security Analysis
- **Purpose**: Static analysis for security vulnerabilities
- **Configuration**: `config/brakeman.yml`
- **Usage**: `bundle exec brakeman`

### 3. **Bundler Audit** - Dependency Security
- **Purpose**: Checks for known vulnerabilities in gems
- **Usage**: `bundle exec bundler-audit check`

## 🚀 GitHub Actions Pipeline

The CI/CD pipeline (`.github/workflows/ci.yml`) includes:

### Security Job
- Bundler audit for vulnerable dependencies
- Brakeman security scan
- Results uploaded as artifacts

### Quality Job
- RuboCop style and quality checks
- Results uploaded as artifacts

### Test Job
- Full test suite with PostgreSQL and Redis
- Asset compilation
- Coverage reporting
- Both Minitest and RSpec support

### Performance Job
- Bullet N+1 query detection
- Performance regression testing

### Deploy Check Job
- Migration status verification
- Credentials validation
- Asset compilation test
- Only runs on main branch

## 🔧 Local Development

### Quick Quality Check
```bash
# Run all quality checks
bundle exec rake quality

# Individual checks
bundle exec rake security
bundle exec rake style
bundle exec rake test
bundle exec rake performance
```

### Auto-fix Style Issues
```bash
bundle exec rake quality:fix
```

### Generate Reports
```bash
bundle exec rake quality:reports
# Creates HTML and JSON reports in tmp/reports/
```

### Pre-commit Hook
```bash
# Install the pre-commit hook
bin/pre-commit --install

# The hook will automatically run before each commit
# To bypass: git commit --no-verify
```

## 📊 Quality Standards

### RuboCop Configuration
- **Line length**: 120 characters
- **Method length**: 25 lines max
- **Class length**: 150 lines max
- **Complexity**: ABC size 20, Cyclomatic 8
- **Style**: Single quotes, trailing commas

### Brakeman Configuration
- **Confidence level**: Medium
- **Exit on warnings**: Yes
- **Comprehensive checks**: All security checks enabled

### Test Requirements
- All tests must pass
- Coverage reporting enabled
- Both unit and integration tests

## 🎯 Workflow Integration

### Pull Request Checks
All PRs must pass:
1. ✅ Security analysis (Brakeman + Bundler Audit)
2. ✅ Code quality (RuboCop)
3. ✅ Test suite (Minitest/RSpec)
4. ✅ Performance checks (Bullet)

### Main Branch Protection
Additional checks for main branch:
1. ✅ Migration status
2. ✅ Credentials validation
3. ✅ Asset compilation
4. ✅ Deployment readiness

## 🔍 Troubleshooting

### RuboCop Issues
```bash
# See what would be auto-fixed
bundle exec rubocop --autocorrect-all --dry-run

# Auto-fix safe issues
bundle exec rubocop --autocorrect-all

# Check specific files
bundle exec rubocop app/models/user.rb
```

### Brakeman False Positives
Add to `config/brakeman.yml`:
```yaml
ignore_warnings:
  - fingerprint: "abc123..."  # Copy from Brakeman output
```

### Bundler Audit Issues
```bash
# Update vulnerability database
bundle exec bundler-audit update

# Check for updates
bundle outdated

# Update specific gem
bundle update gem_name
```

### Test Failures
```bash
# Run specific test
bundle exec rails test test/models/user_test.rb

# Run with verbose output
bundle exec rails test -v

# Run tests matching pattern
bundle exec rails test -n test_user_creation
```

## 📈 Metrics and Monitoring

### Code Quality Metrics
- **RuboCop violations**: Track over time
- **Security issues**: Zero tolerance policy
- **Test coverage**: Aim for >80%
- **Performance**: Monitor N+1 queries

### CI/CD Metrics
- **Build time**: Target <10 minutes
- **Success rate**: Aim for >95%
- **Deployment frequency**: Track releases
- **Lead time**: Measure feature delivery

## 🚀 Deployment Process

### Pre-deployment Checklist
```bash
# Run full quality suite
bundle exec rake quality:deploy_ready

# This checks:
# ✅ Security (Brakeman + Bundler Audit)
# ✅ Style (RuboCop)
# ✅ Tests (Full suite)
# ✅ Migrations (Status check)
# ✅ Credentials (Validation)
# ✅ Assets (Compilation)
```

### Manual Deployment Steps
1. Ensure all CI checks pass
2. Run `bundle exec rake quality:deploy_ready`
3. Create release tag
4. Deploy to staging
5. Run smoke tests
6. Deploy to production
7. Monitor application health

## 🛡️ Security Best Practices

### Regular Maintenance
- **Weekly**: Run `bundle exec bundler-audit update && bundle exec bundler-audit check`
- **Monthly**: Review Brakeman configuration and warnings
- **Quarterly**: Update RuboCop and review style guide changes

### Dependency Management
- Keep gems updated
- Review security advisories
- Use `bundle audit` in CI/CD
- Pin critical gem versions

### Code Review Process
- All PRs require CI/CD checks to pass
- Security-sensitive changes require additional review
- Performance impacts should be measured
- Style violations should be fixed before merge

## 📚 Additional Resources

- [RuboCop Documentation](https://docs.rubocop.org/)
- [Brakeman Documentation](https://brakemanscanner.org/docs/)
- [Bundler Audit](https://github.com/rubysec/bundler-audit)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
