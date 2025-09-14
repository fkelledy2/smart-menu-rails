# Rails Credentials Management Scripts

This directory contains scripts to manage Rails credentials for different environments.

## Available Scripts

### Development
```bash
./bin/credentials/edit_development.sh
```

### Staging
```bash
./bin/credentials/edit_staging.sh
```

### Production
```bash
./bin/credentials/edit_production.sh
```

## Prerequisites

1. Make sure the scripts are executable:
   ```bash
   chmod +x bin/credentials/*.sh
   ```

2. For VS Code users, the scripts are configured to use `code --wait` as the editor. If you're using a different editor, modify the `EDITOR` variable in the scripts.

## First-Time Setup

If you're setting up credentials for the first time in an environment, the script will create the necessary key and encrypted files. You'll need to run the script twice:

1. First run: Creates the encrypted file with empty credentials
2. Second run: Allows you to edit the newly created credentials

## Security Notes

- Never commit the `*.key` files to version control
- The `.key` files are in `.gitignore` by default in Rails
- Keep the master keys secure and share them only with trusted team members
- For production, consider using environment variables for the master key in your deployment environment

## Viewing Credentials

To view the current credentials without editing:

```bash
# For development
EDITOR="cat" bin/rails credentials:show --environment=development

# For staging
EDITOR="cat" bin/rails credentials:show --environment=staging

# For production
EDITOR="cat" bin/rails credentials:show --environment=production
```
