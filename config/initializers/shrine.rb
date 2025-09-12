require "shrine"
require "shrine/storage/file_system"
require "shrine/storage/memory"

# Use file system for development and test, S3 for production
if Rails.env.test?
  Shrine.storages = {
    cache: Shrine::Storage::Memory.new,
    store: Shrine::Storage::Memory.new,
  }
elsif Rails.env.development? || !Rails.application.credentials.dig(:aws, :bucket).present?
  # Use file system in development if S3 is not configured
  Shrine.storages = {
    cache: Shrine::Storage::FileSystem.new("public", prefix: "uploads/cache"),
    store: Shrine::Storage::FileSystem.new("public", prefix: "uploads"),
  }
else
  # Use S3 in production or if explicitly configured in development
  require "shrine/storage/s3"
  
  s3_options = {
    bucket:            Rails.application.credentials.dig(:aws, :bucket),
    access_key_id:     Rails.application.credentials.dig(:aws, :access_key_id),
    secret_access_key: Rails.application.credentials.dig(:aws, :secret_access_key),
    region:            Rails.application.credentials.dig(:aws, :region),
  }
  
  Shrine.storages = {
    cache: Shrine::Storage::S3.new(prefix: "cache", **s3_options),
    store: Shrine::Storage::S3.new(**s3_options),
  }
end

Shrine.plugin :activerecord
Shrine.plugin :cached_attachment_data # for retaining the cached file across form redisplays
Shrine.plugin :restore_cached_data # re-extract metadata when attaching a cached file
Shrine.plugin :validation
Shrine.plugin :validation_helpers
Shrine.plugin :remove_attachment

# Create upload directory if it doesn't exist
if Rails.env.development? && Shrine.storages[:store].is_a?(Shrine::Storage::FileSystem)
  FileUtils.mkdir_p(File.join(Rails.root, "public/uploads"))
  FileUtils.mkdir_p(File.join(Rails.root, "public/uploads/cache"))
end
