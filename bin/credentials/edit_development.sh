#!/bin/bash
# Edit development credentials

# Set environment variables
export RAILS_MASTER_KEY=$(cat config/credentials/development.key)

# Open the credentials in the default editor
EDITOR="vi" bin/rails credentials:edit --environment=development
