#!/bin/bash

# This script updates all genimages by processing them through GenerateImageJob
# Usage: ./scripts/tasks/genimages_update_all.sh

cd "$(dirname "$0")/../.." || exit 1

echo "Starting to update all genimages..."
bundle exec rake genimages:update_all

echo "Genimages update complete!"
