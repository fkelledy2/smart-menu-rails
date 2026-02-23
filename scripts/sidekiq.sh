#!/usr/bin/env bash
# Launch Sidekiq without MallocNanoZone to suppress macOS malloc warnings
bundle exec sidekiq 
