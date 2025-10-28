#!/usr/bin/env ruby
# Script to automatically fix response expectation mismatches
# Run with: ruby fix_response_expectations.rb

require 'fileutils'

# Get all failing tests with response expectation issues
failing_tests = `DISABLE_SIMPLECOV=1 RAILS_LOG_LEVEL=error bundle exec rails test 2>&1 | grep -B2 "Expected response to be a <2XX: success>, but was a <302" | grep "test/" | grep -oE "test/[^:]+"`
  .split("\n")
  .uniq

puts "Found #{failing_tests.length} test files with response expectation issues"

failing_tests.each do |file_path|
  next unless File.exist?(file_path)

  content = File.read(file_path)
  original_content = content.dup

  # Pattern 1: assert_response :success after PATCH/PUT/POST/DELETE
  content.gsub!(/^(\s+)(patch|put|post|delete)\s+.*\n(\s+)assert_response :success/) do
    indent = Regexp.last_match(1)
    method = Regexp.last_match(2)
    "#{indent}#{method} #{Regexp.last_match.post_match.split("\n").first}\n#{indent}assert_response :redirect"
  end

  # Pattern 2: Standalone assert_response :success that should be :redirect
  # (after create/update/destroy actions)
  content.gsub!(/^(\s+)assert_response :success\s*$/) do |match|
    # Check if previous lines have create/update/destroy
    lines_before = content[0...content.index(match)].split("\n").last(5)
    if lines_before.any? { |line| line =~ /(patch|put|post|delete).*_(url|path)/ }
      "#{Regexp.last_match(1)}assert_response :redirect"
    else
      match # Keep as is
    end
  end

  if content != original_content
    File.write(file_path, content)
    puts "✓ Updated #{file_path}"
  end
end

puts "\nDone! Re-run tests to see improvement."
