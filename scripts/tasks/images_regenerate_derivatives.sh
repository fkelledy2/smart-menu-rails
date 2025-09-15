#!/bin/bash

# This script regenerates all image derivatives for Menuitems and Menusections
# Usage: ./scripts/tasks/images_regenerate_derivatives.sh

cd "$(dirname "$0")/../.." || exit 1

echo "Starting to regenerate image derivatives..."
bundle exec rake images:regenerate_derivatives

echo "Image derivatives regeneration complete!"
