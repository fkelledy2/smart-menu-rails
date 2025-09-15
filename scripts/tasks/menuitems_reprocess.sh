#!/bin/bash

# This script processes all menu items to ensure they have associated Genimage records
# Usage: ./scripts/tasks/menuitems_reprocess.sh

cd "$(dirname "$0")/../.." || exit 1

echo "Starting to process all menuitems..."
bundle exec rake menuitems:reprocess

echo "Menuitems processing complete!"
