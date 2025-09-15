#!/bin/bash

# This script processes all menu items to ensure they have associated Genimage records
# Usage: ./scripts/tasks/menuitems_process_all.sh

cd "$(dirname "$0")/../.." || exit 1

echo "Starting to process all menu items..."
bundle exec rake menuitems:process_all

echo "Menu items processing complete!"
