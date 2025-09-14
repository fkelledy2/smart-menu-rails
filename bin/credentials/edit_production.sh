#!/bin/bash
# Edit production credentials

# Check if key file exists
if [ ! -f "config/credentials/production.key" ]; then
  echo "Creating new production credentials..."
  EDITOR="echo "\n" > " bin/rails credentials:edit --environment=production
  echo "Please run the script again to edit the credentials"
  exit 1
fi

# Set environment variables
export RAILS_MASTER_KEY=$(cat config/credentials/production.key)

# Open the credentials in the default editor
EDITOR="code --wait" bin/rails credentials:edit --environment=production
