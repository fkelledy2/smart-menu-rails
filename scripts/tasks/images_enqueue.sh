#!/bin/bash

# This script queues image resizing for all existing records with images
# Usage: ./scripts/tasks/images_enqueue.sh

cd "$(dirname "$0")/../.." || exit 1

echo "Starting to enqueue image resizing for all records with images..."
bundle exec rake images:enqueue

echo "Image resizing has been queued for all relevant records!"
