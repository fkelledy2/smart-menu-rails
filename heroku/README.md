# Heroku Multi-Environment Setup

This directory contains scripts for managing Heroku deployments across three environments: Development, Staging, and Production.

## Directory Structure

```
heroku/
├── dev/
│   ├── setup.sh                    # Initial setup for development environment
│   ├── deploy.sh                   # Deploy to development
│   ├── config.sh                   # View/manage development config vars
│   ├── tail.sh                     # Tail logs for development
│   └── update_plan_item_limits.sh  # Update plan item limits
├── staging/
│   ├── setup.sh                    # Initial setup for staging environment
│   ├── deploy.sh                   # Deploy to staging
│   ├── config.sh                   # View/manage staging config vars
│   ├── tail.sh                     # Tail logs for staging
│   └── update_plan_item_limits.sh  # Update plan item limits
├── production/
│   ├── setup.sh                    # Initial setup for production environment
│   ├── deploy.sh                   # Deploy to production (with confirmation)
│   ├── config.sh                   # View/manage production config vars
│   ├── tail.sh                     # Tail logs for production
│   └── update_plan_item_limits.sh  # Update plan item limits (with confirmation)
└── README.md                       # This file
```

## Environment Details

### Development (`smart-menus-dev`)
- **Purpose**: Active development and testing
- **Region**: EU
- **Stack**: heroku-22
- **Database**: PostgreSQL Essential
- **Redis**: Mini
- **Storage**: Bucketeer Hobbyist
- **Config**: `RAILS_ENV=development`, debug logging enabled

### Staging (`smart-menus-staging`)
- **Purpose**: Pre-production testing and QA
- **Region**: EU
- **Stack**: heroku-22
- **Database**: PostgreSQL Standard
- **Redis**: Premium
- **Storage**: Bucketeer Hobbyist
- **Config**: `RAILS_ENV=staging`, production-like settings

### Production (`smart-menus`)
- **Purpose**: Live production environment
- **Region**: EU
- **Stack**: heroku-22
- **Database**: PostgreSQL Standard
- **Redis**: Premium
- **Storage**: Bucketeer Hobbyist
- **Config**: `RAILS_ENV=production`, optimized for performance

## Usage

### Initial Setup

Run the setup script for each environment (only needed once):

```bash
# Development
./heroku/dev/setup.sh

# Staging
./heroku/staging/setup.sh

# Production
./heroku/production/setup.sh
```

### Deployment

Deploy code to an environment:

```bash
# Deploy to development (from main branch)
./heroku/dev/deploy.sh

# Deploy to staging (from specific branch)
./heroku/staging/deploy.sh feature-branch

# Deploy to production (requires confirmation)
./heroku/production/deploy.sh
```

### Configuration Management

View and manage environment variables:

```bash
# View development config
./heroku/dev/config.sh

# View staging config
./heroku/staging/config.sh

# View production config
./heroku/production/config.sh
```

### Log Monitoring

Tail logs in real-time for each environment:

```bash
# Tail development logs
./heroku/dev/tail.sh

# Tail staging logs
./heroku/staging/tail.sh

# Tail production logs
./heroku/production/tail.sh
```

You can pass additional options to filter logs:

```bash
# Only show web dyno logs
./heroku/dev/tail.sh --ps web

# Only show worker dyno logs
./heroku/staging/tail.sh --ps worker

# Only show app logs (exclude Heroku platform logs)
./heroku/production/tail.sh --source app

# Combine options
./heroku/production/tail.sh --ps web --source app
```

### Plan Item Limits Management

Update plan item limits (itemspermenu) for Professional and Business plans:

```bash
# Development - test with dry-run first
./heroku/dev/update_plan_item_limits.sh --dry-run
./heroku/dev/update_plan_item_limits.sh

# Staging - test with dry-run first
./heroku/staging/update_plan_item_limits.sh --dry-run
./heroku/staging/update_plan_item_limits.sh

# Production - ALWAYS test with dry-run first!
./heroku/production/update_plan_item_limits.sh --dry-run
./heroku/production/update_plan_item_limits.sh  # Requires confirmation
```

**What it does:**
- Updates `itemspermenu` limit for Professional plan to 150
- Updates `itemspermenu` limit for Business plan to 300
- Supports both old plan keys (`plan.pro.key`, `plan.business.key`) and new keys (`professional`, `business`)
- Production version requires explicit confirmation for safety

**Best Practice:**
Always run with `--dry-run` first to see what will change before applying updates!

To set config variables:

```bash
# Development
heroku config:set VARIABLE_NAME=value -a smart-menus-dev

# Staging
heroku config:set VARIABLE_NAME=value -a smart-menus-staging

# Production
heroku config:set VARIABLE_NAME=value -a smart-menus
```

## Required Configuration Variables

After running setup, you'll need to configure these variables for each environment:

### Authentication & OAuth
- `GOOGLE_CLIENT_ID` / `GOOGLE_CLIENT_SECRET`
- `APPLE_CLIENT_ID` / `APPLE_TEAM_ID` / `APPLE_KEY_ID` / `APPLE_P8_KEY`

### Payment Processing
- `STRIPE_SECRET_KEY` (test keys for dev/staging, live key for production)
- `STRIPE_WEBHOOK_SECRET`

### External Services
- `GOOGLE_MAPS_API_KEY`
- `SENTRY_DSN` (optional but recommended for error tracking)

### Storage (Auto-configured by Bucketeer add-on)
- `BUCKETEER_AWS_ACCESS_KEY_ID`
- `BUCKETEER_AWS_SECRET_ACCESS_KEY`
- `BUCKETEER_AWS_REGION`
- `BUCKETEER_BUCKET_NAME`

## Common Tasks

### View Logs
```bash
# Development (using convenience script)
./heroku/dev/tail.sh

# Staging (using convenience script)
./heroku/staging/tail.sh

# Production (using convenience script)
./heroku/production/tail.sh

# Or use heroku CLI directly:
heroku logs --tail -a smart-menus-dev
heroku logs --tail -a smart-menus-staging
heroku logs --tail -a smart-menus
```

### Run Migrations
```bash
# Development
heroku run rails db:migrate -a smart-menus-dev

# Staging
heroku run rails db:migrate -a smart-menus-staging

# Production
heroku run rails db:migrate -a smart-menus
```

### Open Console
```bash
# Development
heroku run rails console -a smart-menus-dev

# Staging
heroku run rails console -a smart-menus-staging

# Production
heroku run rails console -a smart-menus
```

### Scale Dynos
```bash
# Development (minimal)
heroku ps:scale web=1:basic worker=1:basic -a smart-menus-dev

# Staging (moderate)
heroku ps:scale web=2:standard-1x worker=1:standard-1x -a smart-menus-staging

# Production (scale as needed)
heroku ps:scale web=3:standard-2x worker=2:standard-1x -a smart-menus
```

## Best Practices

1. **Always test in development first** before deploying to staging or production
2. **Use staging for final QA** before production deployments
3. **Production deployments require confirmation** - the script will prompt you
4. **Keep config vars in sync** across environments (except for API keys)
5. **Use test API keys** for development and staging
6. **Monitor logs** after deployments to catch issues early
7. **Run migrations** explicitly if needed (though release phase should handle this)

## Troubleshooting

### App doesn't exist
Run the setup script for that environment.

### Build fails
Check buildpack order (Node.js first, then Ruby):
```bash
heroku buildpacks -a <app-name>
```

### Database issues
Check if PostgreSQL add-on is provisioned:
```bash
heroku addons -a <app-name>
```

### Config vars missing
Run the config script to see what's set, then add missing variables.

## Support

For Heroku-specific issues, consult:
- [Heroku Dev Center](https://devcenter.heroku.com/)
- [Heroku Status](https://status.heroku.com/)

For application-specific issues, check the main project documentation.
