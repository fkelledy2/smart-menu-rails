#!/bin/bash
# Edit staging credentials

# Check if key file exists
if [ ! -f "config/credentials/staging.key" ]; then
  echo "Creating new staging credentials..."
  EDITOR="echo "\n" > " bin/rails credentials:edit --environment=staging
  echo "Please run the script again to edit the credentials"
  exit 1
fi

# Set environment variables
export RAILS_MASTER_KEY=$(cat config/credentials/staging.key)

# Open the credentials in the default editor
EDITOR="code --wait" bin/rails credentials:edit --environment=staging
