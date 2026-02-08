#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require 'fileutils'
require 'optparse'

ROOT = File.expand_path('..', __dir__)
LOCALES_DIR = File.join(ROOT, 'config', 'locales')

def deep_dup(obj)
  Marshal.load(Marshal.dump(obj))
end

def deep_slice(source, template)
  return nil unless source.is_a?(Hash) && template.is_a?(Hash)

  out = {}
  template.each do |k, v|
    next unless source.key?(k)

    if v.is_a?(Hash) && source[k].is_a?(Hash)
      sliced = deep_slice(source[k], v)
      out[k] = sliced unless sliced.nil? || sliced.empty?
    else
      out[k] = source[k]
    end
  end

  out
end

def deep_delete!(source, template)
  return unless source.is_a?(Hash) && template.is_a?(Hash)

  template.each do |k, v|
    next unless source.key?(k)

    if v.is_a?(Hash) && source[k].is_a?(Hash)
      deep_delete!(source[k], v)
      source.delete(k) if source[k].respond_to?(:empty?) && source[k].empty?
    else
      source.delete(k)
    end
  end
end

def load_yaml(path)
  YAML.load_file(path) || {}
end

def dump_yaml(hash)
  # Keep output stable and human-readable.
  YAML.dump(hash)
end

options = {
  locales_dir: LOCALES_DIR,
  dry_run: false,
  force: false,
  write_misc: true,
}

parser = OptionParser.new do |opts|
  opts.banner = "Usage: ruby scripts/split_locale_by_feature.rb --locale <fr> --input config/locales/fr/fr.yml [options]"

  opts.on('--locale LOCALE', 'Target locale code (e.g. fr, de, es, pt, cs, hu)') { |v| options[:locale] = v }
  opts.on('--input PATH', 'Input monolithic locale yml path (defaults to config/locales/<locale>/<locale>.yml)') { |v| options[:input] = v }
  opts.on('--locales-dir PATH', 'Locales directory (defaults to config/locales)') { |v| options[:locales_dir] = v }
  opts.on('--dry-run', 'Do not write files, only print what would happen') { options[:dry_run] = true }
  opts.on('--force', 'Overwrite existing output files') { options[:force] = true }
  opts.on('--no-misc', 'Do not write misc.<locale>.yml for leftover keys') { options[:write_misc] = false }
end

parser.parse!

locale = options[:locale]
if locale.nil? || locale.strip.empty?
  warn(parser.to_s)
  exit(1)
end

input_path = options[:input] || File.join(options[:locales_dir], locale, "#{locale}.yml")
unless File.exist?(input_path)
  warn("Input file not found: #{input_path}")
  exit(1)
end

# Canonical template files are all *.en.yml split-by-feature files.
# We intentionally exclude region-specific en_US/en_GB and the monolithic en.yml.
template_paths = Dir.glob(File.join(options[:locales_dir], '**', '*.en.yml'))
  .reject { |p| File.basename(p) =~ /\Aen_(US|GB)\.yml\z/ }
  .reject { |p| File.basename(p) == 'en.yml' }

if template_paths.empty?
  warn("No template files found at #{options[:locales_dir]}/**/*.en.yml")
  exit(1)
end

input = load_yaml(input_path)
source = input.fetch(locale) do
  # If someone used :en style root inside a different filename, try to detect it
  input.values.find { |v| v.is_a?(Hash) } || {}
end

remaining = deep_dup(source)

planned_writes = []

template_paths.sort.each do |template_path|
  template_yaml = load_yaml(template_path)
  template = template_yaml.fetch('en', {})

  sliced = deep_slice(remaining, template)
  next if sliced.nil? || sliced.empty?

  out_hash = { locale => sliced }

  out_name = File.basename(template_path).sub(/\.en\.yml\z/, ".#{locale}.yml")
  out_path = File.join(options[:locales_dir], locale, out_name)

  planned_writes << [out_path, out_hash]

  # Remove from remaining based on the same template so misc contains only leftovers.
  deep_delete!(remaining, template)
end

misc_out_path = File.join(options[:locales_dir], locale, "misc.#{locale}.yml")

if options[:write_misc] && remaining.is_a?(Hash) && !remaining.empty?
  planned_writes << [misc_out_path, { locale => remaining }]
end

if planned_writes.empty?
  puts("No keys from #{input_path} matched the en templates. Nothing to write.")
  exit(0)
end

planned_writes.each do |path, content|
  exists = File.exist?(path)
  if exists && !options[:force]
    warn("Skip (exists, use --force to overwrite): #{path}")
    next
  end

  puts("#{options[:dry_run] ? 'Would write' : 'Writing'} #{path}")
  next if options[:dry_run]

  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, dump_yaml(content))
end

puts("Done. Review generated files and then consider removing the monolithic #{input_path} once verified.")
